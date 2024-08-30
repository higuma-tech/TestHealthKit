//
//  HealthKitController.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/08/27.
//

import Foundation
import HealthKit
import os

struct HealthDataType: Identifiable, Hashable {
    var value: Double
    var valueString: String
    var dayString: String
    var dayOfWeekString: String
    var id = UUID()
}

class HealthKitController {
    private let healthStore = HKHealthStore()
    private let isAvailable = HKHealthStore.isHealthDataAvailable()
    
    let logger = Logger(subsystem: "com.example.ebata-samplecode.TestHealthKit.HealthKitController",
                        category: "HealthKit")
    
    public func requestHealthDataAccessIfNeeded(toShare shareTypes: Set<HKSampleType>?,
                                                read readTypes: Set<HKObjectType>?,
                                                completion: @escaping (_ success: Bool) -> Void) async {
        
        let result = await requestHealthDataAccessIfNeeded(toShare: shareTypes, read: readTypes)
        completion(result)
    }
    
    // MARK: - Authorization
    
    public func requestHealthDataAccessIfNeeded(toShare shareTypes: Set<HKSampleType>?,
                                                read readTypes: Set<HKObjectType>?) async -> Bool {
        guard isAvailable else {
            return false
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: shareTypes!, read: readTypes!)
            return true
        } catch let error {
            self.logger.error("An error occurred while requesting HealthKit Authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Set
    
    private func getHKUnit(identifier: HKQuantityTypeIdentifier) -> HKUnit {
        var unitString = ""
        switch identifier {
        case .stepCount:
            unitString = "count"
        case .distanceWalkingRunning:
            unitString = "m"
        case .sixMinuteWalkTestDistance:
            unitString = "m"
        default:
            unitString = "count"
        }
        
        let unit = HKUnit(from: unitString)
        return unit
    }
        
    public func setStepCountToHKStatictics(value:Double, date:Date) async -> Bool {
        let quantityTypeIdentifier = HKQuantityTypeIdentifier.stepCount
        let result = await saveToHKStatistics(quantityTypeIdentifier: quantityTypeIdentifier, value:value, date:date)
        return result
    }
    
    public func saveToHKStatistics(quantityTypeIdentifier: HKQuantityTypeIdentifier, value:Double, date:Date) async -> Bool {
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let startDate = calendar.date(from: components) else {
            return false
        }
        
        let endDate = date
//        guard let startDate: Date = calendar.date(byAdding: .day, value: -1, to: endDate) else {
//            return false
//        }
        
        let unit = getHKUnit(identifier: quantityTypeIdentifier)
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let quantityType = HKQuantityType.quantityType(forIdentifier: quantityTypeIdentifier)!
        let quantitySample = HKQuantitySample(type: quantityType, quantity: quantity, start: startDate, end: endDate)
        do {
            try await healthStore.save(quantitySample)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Get
    
    public var readDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    public var shareDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    public var allHealthDataTypes: [HKSampleType] {
        let typeIdentifiers: [String] = [
            HKQuantityTypeIdentifier.stepCount.rawValue,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
            HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue
        ]
        
        return typeIdentifiers.compactMap { getSampleType(for: $0) }
    }
    
    public func getSampleType(for identifier: String) -> HKSampleType? {
        if let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier)) {
            return quantityType
        }
        
        if let categoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier)) {
            return categoryType
        }
        
        return nil
    }
    
    private func getHKStatisticsOptions(forIdentifier identifier:HKQuantityTypeIdentifier) -> HKStatisticsOptions {
        var options:HKStatisticsOptions
        
        switch identifier {
        case HKQuantityTypeIdentifier.stepCount:
            options = .cumulativeSum
        case HKQuantityTypeIdentifier.distanceWalkingRunning:
            options = .cumulativeSum
        case HKQuantityTypeIdentifier.sixMinuteWalkTestDistance:
            options = .discreteAverage
        default:
            options = .mostRecent
        }
        
        return options
    }
    
    public func QueryStatisticsCollection(forIdentifier identifier:HKQuantityTypeIdentifier) async ->  HKStatisticsCollection? {
        
        let calendar = Calendar.current
 
        let interval = DateComponents(day: 1)
        
        let anchorDateComponents = DateComponents(calendar: calendar,
                                        timeZone: calendar.timeZone,
                                        hour: 0,
                                        minute: 0,
                                        second: 0,
                                        weekday: 2)     // Set anchor date to Monday at midnight 
        
        guard let anchorDate = calendar.nextDate(after: Date(),
                                                 matching: anchorDateComponents,
                                                 matchingPolicy: .nextTime,
                                                 repeatedTimePolicy: .first,
                                                 direction: .backward) else {
            fatalError("*** unable to find the previous Monday. ***")
        }
                
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            fatalError("*** Unable to create a step count type ***")
        }
        
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let midnight = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        let startDate = calendar.date(byAdding: .day, value: -6, to: midnight)!
        let endDate = now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let quantitySamplePredicate = HKSamplePredicate.quantitySample(type: quantityType, predicate: predicate)

        let options:HKStatisticsOptions = getHKStatisticsOptions(forIdentifier: identifier)
        
        // Create the query.
        let query = HKStatisticsCollectionQueryDescriptor(predicate: quantitySamplePredicate,
                                                          options: options,
                                                          anchorDate: anchorDate,
                                                          intervalComponents: interval)
        do {
            let collection = try await query.result(for: healthStore)
            return Optional(collection)
        } catch {
            return nil
        }
    }
    
    public func getStringArrayFromHKStatisticsCollection(identifier:HKQuantityTypeIdentifier, collection: HKStatisticsCollection?) -> [[String]] {
        
        guard let statsCollection = collection else {
            // You should only hit this case if you have an unhandled error. Check for bugs
            // in your code that creates the query, or explicitly handle the error.
            assertionFailure("")
            return []
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let midnight = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        let startDate = calendar.date(byAdding: .day, value: -6, to: midnight)!
//        let startDate = calendar.date(byAdding: .day, value: -6, to: now)!
        let endDate = now
        var itemArray:[[String]] = []
        
        // Enumerate over all the statistics objects between the start and end dates.
        statsCollection.enumerateStatistics(from: startDate, to: endDate)
        { (statistics, stop) in
            //print("stop:", stop.pointee)
            var unitString:String
            var resultOrNil: HKQuantity?
            var value: Int
            
            switch identifier {
            case HKQuantityTypeIdentifier.stepCount:
                resultOrNil = statistics.sumQuantity()
                unitString = " steps"
                if let result = resultOrNil {
                    value = Int((result.doubleValue(for: HKUnit.count())))
                } else {
                    value = 0
                }
            case HKQuantityTypeIdentifier.distanceWalkingRunning:
                resultOrNil = statistics.sumQuantity()
                unitString = " m"
                if let result = resultOrNil {
                    value = Int((result.doubleValue(for: HKUnit.meter())))
                } else {
                    value = 0
                }
            case HKQuantityTypeIdentifier.sixMinuteWalkTestDistance:
                resultOrNil = statistics.averageQuantity()
                unitString = " m"
                if let result = resultOrNil {
                    value = Int((result.doubleValue(for: HKUnit.meter())))
                } else {
                    value = 0
                }
            default:
                resultOrNil = statistics.mostRecentQuantity()
                unitString = " count"
                if let result = resultOrNil {
                    value = Int((result.doubleValue(for: HKUnit.count())))
                } else {
                    value = 0
                }
            }
            
            var item:[String] = []
            let labelText = String(value) + unitString
            item.append(labelText)
            
            // get start date string
            let startDateString = self.getStartDateFromHKStatistics(statistics:statistics)
            item.append(startDateString)
            itemArray.append(item)
        }
        
        return itemArray
    }
    
    public func getStartDateFromHKStatistics(statistics:HKStatistics) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let startDateString = dateFormatter.string(from: statistics.startDate)
        
        return startDateString
    }
    
    public func getStartDateFromHKStatistics(statistics:HKStatistics, style:DateFormatter.Style) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = style
        dateFormatter.timeStyle = .none
        let startDateString = dateFormatter.string(from: statistics.startDate)
        
        return startDateString
    }
    
    public func getStartDayOfWeekFromHKStatistics(statistics:HKStatistics) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let dayOfWeek = dateFormatter.string(from: statistics.startDate)
        return dayOfWeek
    }
    
    // called by HealthDataChartView
    public func getValueAndDayFromHKStatisticsCollection(identifier:HKQuantityTypeIdentifier, collection: HKStatisticsCollection?) -> [HealthDataType] {
        
        guard let statsCollection = collection else {
            // You should only hit this case if you have an unhandled error. Check for bugs
            // in your code that creates the query, or explicitly handle the error.
            assertionFailure("")
            return []
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let midnight = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        let startDate = calendar.date(byAdding: .day, value: -6, to: midnight)!
 
        let endDate = now
        var healthData:HealthDataType = HealthDataType(value:0, valueString:"", dayString:"", dayOfWeekString: "")
        var healthDataArray:[HealthDataType] = []
        
        // Enumerate over all the statistics objects between the start and end dates.
        statsCollection.enumerateStatistics(from: startDate, to: endDate)
        { (statistics, stop) in
            //print("stop:", stop.pointee)
            var resultOrNil: HKQuantity?
            var value: Double
            switch identifier {
            case HKQuantityTypeIdentifier.stepCount:
                resultOrNil = statistics.sumQuantity()
                if let result = resultOrNil {
                    value = result.doubleValue(for: HKUnit.count())
                } else {
                    value = 0
                }
            case HKQuantityTypeIdentifier.distanceWalkingRunning:
                resultOrNil = statistics.sumQuantity()
                if let result = resultOrNil {
                    value = result.doubleValue(for: HKUnit.meter())
                } else {
                    value = 0
                }
            case HKQuantityTypeIdentifier.sixMinuteWalkTestDistance:
                resultOrNil = statistics.averageQuantity()
                if let result = resultOrNil {
                    value = result.doubleValue(for: HKUnit.meter())
                } else {
                    value = 0
                }
            default:
                resultOrNil = statistics.mostRecentQuantity()
                if let result = resultOrNil {
                    value = result.doubleValue(for: HKUnit.count())
                } else {
                    value = 0
                }
            }
            
            healthData.value = value
            healthData.dayString = self.getStartDateFromHKStatistics(statistics:statistics, style:.short)
            healthData.dayOfWeekString = self.getStartDayOfWeekFromHKStatistics(statistics:statistics)
            healthDataArray.append(healthData)
        }
        
        return healthDataArray
    }
    
    private func getUnitString(forIdentifier identifier:HKQuantityTypeIdentifier) -> String {
        var unitString:String = ""
        
        switch identifier {
        case .stepCount:
            unitString = "steps"
        case .distanceWalkingRunning:
            unitString = "m"
        case .sixMinuteWalkTestDistance:
            unitString = "m"
        default:
            unitString = "count"
        }
        
        return unitString
    }
    
    private func getQuntityFromHKStatistics(forIdentifier identifier:HKQuantityTypeIdentifier, statistics:HKStatistics) -> Double {
        var quantity: HKQuantity?
        var value: Double
        
        switch identifier {
        case .stepCount:
            quantity = statistics.sumQuantity()
            if let quantity = quantity {
                value = quantity.doubleValue(for: HKUnit.count())
            } else {
                value = 0
            }
        case .distanceWalkingRunning:
            quantity = statistics.sumQuantity()
            if let quantity = quantity {
                value = quantity.doubleValue(for: HKUnit.meter())
            } else {
                value = 0
            }
        case .sixMinuteWalkTestDistance:
            quantity = statistics.averageQuantity()
            if let quantity = quantity {
                value = quantity.doubleValue(for: HKUnit.meter())
            } else {
                value = 0
            }
        default:
            quantity = statistics.mostRecentQuantity()
            if let quantity = quantity {
                value = quantity.doubleValue(for: HKUnit.count())
            } else {
                value = 0
            }
        }
        
        return value
    }
    
    public func getHealthDateFromHKStatisticsCollection(identifier:HKQuantityTypeIdentifier, collection: HKStatisticsCollection?) -> [HealthDataType] {
        
        guard let statsCollection = collection else {
            // You should only hit this case if you have an unhandled error. Check for bugs
            // in your code that creates the query, or explicitly handle the error.
            assertionFailure("")
            return []
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let midnight = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        let startDate = calendar.date(byAdding: .day, value: -6, to: midnight)!
 
        let endDate = now
        var healthData:HealthDataType = HealthDataType(value:0, valueString:"", dayString:"", dayOfWeekString: "")
        var healthDataArray:[HealthDataType] = []
        
        // Enumerate over all the statistics objects between the start and end dates.
        statsCollection.enumerateStatistics(from: startDate, to: endDate)
        { (statistics, stop) in
            healthData.value = self.getQuntityFromHKStatistics(forIdentifier:identifier, statistics: statistics)
            let unitString = self.getUnitString(forIdentifier:identifier)
            healthData.valueString = String(Int(healthData.value)) + " " + unitString
            healthData.dayString = self.getStartDateFromHKStatistics(statistics:statistics, style:.short)
            healthData.dayOfWeekString = self.getStartDayOfWeekFromHKStatistics(statistics:statistics)
            healthDataArray.append(healthData)
        }
        
        return healthDataArray
    }
}
