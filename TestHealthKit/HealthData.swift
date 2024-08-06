//
//  HealthData.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/07/29.
//

import Foundation
import HealthKit

struct HealthDataType: Identifiable {
    var day: String
    var value: Double
    var dayOfWeek: String
    var id = UUID()
}

class HealthData {
    
    static var healthStore: HKHealthStore = HKHealthStore()
    
    static var readDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    static var shareDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    private static var allHealthDataTypes: [HKSampleType] {
        let typeIdentifiers: [String] = [
            HKQuantityTypeIdentifier.stepCount.rawValue,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
            HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue
        ]
        
        return typeIdentifiers.compactMap { getSampleType(for: $0) }
    }
    
    static func getSampleType(for identifier: String) -> HKSampleType? {
        if let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier)) {
            return quantityType
        }
        
        if let categoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier)) {
            return categoryType
        }
        
        return nil
    }
    
    /// Request health data from HealthKit if needed.
    class func requestHealthDataAccessIfNeeded(toShare shareTypes: Set<HKSampleType>?,
                                               read readTypes: Set<HKObjectType>?,
                                               completion: @escaping (_ success: Bool) -> Void) {
        if HKHealthStore.isHealthDataAvailable() {
            print("Requesting HealthKit authorization...")
            healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
                if let error = error {
                    print("requestAuthorization error:", error.localizedDescription)
                }
                
                if success {
                    print("HealthKit authorization request was successful!")
                } else {
                    print("HealthKit authorization was not successful.")
                }
                
                completion(success)
            }
        } else {
            fatalError("Health data is not available!")
        }
    }
    
    func getSampleType(for identifier: String) -> HKSampleType? {
        if let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier)) {
            return quantityType
        }
        
        if let categoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier)) {
            return categoryType
        }
        
        return nil
    }
    
    /// Return an anchor date for a statistics collection query.
    func createAnchorDate() -> Date {
        // Set the arbitrary anchor date to Monday at 3:00 a.m.
        let calendar: Calendar = .current
        var anchorComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        let offset = (7 + (anchorComponents.weekday ?? 0) - 2) % 7
        
        anchorComponents.day! -= offset
        anchorComponents.hour = 3
        
        let anchorDate = calendar.date(from: anchorComponents)!
        
        return anchorDate
    }
    
    /// This is commonly used for date intervals so that we get the last seven days worth of data,
    /// because we assume today (`Date()`) is providing data as well.
    func getLastWeekStartDate(from date: Date = Date()) -> Date {
        return Calendar.current.date(byAdding: .day, value: -6, to: date)!
    }
    
    func createLastWeekPredicate(from endDate: Date = Date()) -> NSPredicate {
        let startDate = getLastWeekStartDate(from: endDate)
        return HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    }
    
    /// Return the most preferred `HKStatisticsOptions` for a data type identifier. Defaults to `.discreteAverage`.
    func getStatisticsOptions(for dataTypeIdentifier: String) -> HKStatisticsOptions {
        var options: HKStatisticsOptions = .discreteAverage
        let sampleType = getSampleType(for: dataTypeIdentifier)
        
        if sampleType is HKQuantityType {
            let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: dataTypeIdentifier)
            
            switch quantityTypeIdentifier {
            case .stepCount, .distanceWalkingRunning:
                options = .cumulativeSum
            case .sixMinuteWalkTestDistance:
                options = .discreteAverage
            default:
                break
            }
        }
        
        return options
    }
    
    /// Return the statistics value in `statistics` based on the desired `statisticsOption`.
    func getStatisticsQuantity(for statistics: HKStatistics, with statisticsOptions: HKStatisticsOptions) -> HKQuantity? {
        var statisticsQuantity: HKQuantity?
        
        switch statisticsOptions {
        case .cumulativeSum:
            statisticsQuantity = statistics.sumQuantity()
        case .discreteAverage:
            statisticsQuantity = statistics.averageQuantity()
        default:
            break
        }
        
        return statisticsQuantity
    }
    
    class func getStepCount(operation:@escaping((_ stepCount:Int)->Void)) -> Void {
        let calendar = NSCalendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let startDate = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            fatalError("*** Unable to create the end date ***")
        }
        let today = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        var steps = 0
        
        let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: today, options:.cumulativeSum) {query, statisticsOrNil, error in
            
            guard let statistics = statisticsOrNil else {
                // Handle any errors here.
                print("error in HKStatisticsQuery()")
                return
            }
            
            let sum = statistics.sumQuantity()
            steps = Int((sum?.doubleValue(for: HKUnit.count()))!)
            operation(steps)
        }
        HealthData.healthStore.execute(query)
    }
    
    class func StatisticsQueryForHKQuantityTypeIdentifier(identifier:HKQuantityTypeIdentifier, operation:@escaping((_ sum:HKQuantity?)->Void)) -> Void {
        let calendar = NSCalendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let startDate = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            fatalError("*** Unable to create the end date ***")
        }
        let today = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let type = HKQuantityType.quantityType(forIdentifier: identifier)!
        
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
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: today, options: options) {query, statisticsOrNil, error in
            
            guard let statistics = statisticsOrNil else {
                // Handle any errors here.
                print("error in HKStatisticsQuery()")
                return
            }
            
            var result: HKQuantity?
            switch options {
            case .cumulativeSum:
                result = statistics.sumQuantity()
            case .discreteAverage:
                result = statistics.averageQuantity()
            case .mostRecent:
                result = statistics.mostRecentQuantity()
            default:
                result = statistics.mostRecentQuantity()
            }
            operation(result)
        }
        HealthData.healthStore.execute(query)
    }
    
    class func StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier:HKQuantityTypeIdentifier, operation:@escaping((_ collection:HKStatisticsCollection?)->Void)) -> Void {
        
        let calendar = Calendar.current
        let interval = DateComponents(day: 1)
        let components = DateComponents(calendar: calendar,
                                        timeZone: calendar.timeZone,
                                        hour: 3,
                                        minute: 0,
                                        second: 0,
                                        weekday: 2)
        
        
        guard let anchorDate = calendar.nextDate(after: Date(),
                                                 matching: components,
                                                 matchingPolicy: .nextTime,
                                                 repeatedTimePolicy: .first,
                                                 direction: .backward) else {
            fatalError("*** unable to find the previous Monday. ***")
        }
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            fatalError("*** Unable to create a step count type ***")
        }
        
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
        
        // Create the query.
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: nil,
                                                options: options,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)
        // Set the results handler.
        query.initialResultsHandler = {
            query, results, error in
            
            // Handle errors here.
            if let error = error as? HKError {
                switch (error.code) {
                case .errorDatabaseInaccessible:
                    // HealthKit couldn't access the database because the device is locked.
                    return
                default:
                    // Handle other HealthKit errors here.
                    return
                }
            }
            
            operation(results)
        }
        
        HealthData.healthStore.execute(query)
    }
    
    class func getStringArrayFromHKStatisticsCollection(identifier:HKQuantityTypeIdentifier, collection: HKStatisticsCollection?) -> [[String]] {
        
        guard let statsCollection = collection else {
            // You should only hit this case if you have an unhandled error. Check for bugs
            // in your code that creates the query, or explicitly handle the error.
            assertionFailure("")
            return []
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: now)!
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
            let startDateString = getStartDateFromHKStatistics(statistics:statistics)
            item.append(startDateString)
            itemArray.append(item)
        }
        
        return itemArray
    }
    
    class func getStartDateFromHKStatistics(statistics:HKStatistics) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let startDateString = dateFormatter.string(from: statistics.startDate)
        
        return startDateString
    }
    
    class func getStartDateFromHKStatistics(statistics:HKStatistics, style:DateFormatter.Style) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = style
        dateFormatter.timeStyle = .none
        let startDateString = dateFormatter.string(from: statistics.startDate)
        
        return startDateString
    }
    
    class func getStartDayOfWeekFromHKStatistics(statistics:HKStatistics) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let dayOfWeek = dateFormatter.string(from: statistics.startDate)
        return dayOfWeek
    }
    
    class func getValueAndDayFromHKStatisticsCollection(identifier:HKQuantityTypeIdentifier, collection: HKStatisticsCollection?) -> [HealthDataType] {
        
        guard let statsCollection = collection else {
            // You should only hit this case if you have an unhandled error. Check for bugs
            // in your code that creates the query, or explicitly handle the error.
            assertionFailure("")
            return []
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: now)!
        let endDate = now
        var healthData:HealthDataType = HealthDataType(day:"", value:0, dayOfWeek: "")
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
            healthData.day = getStartDateFromHKStatistics(statistics:statistics, style:.short)
            healthData.dayOfWeek = getStartDayOfWeekFromHKStatistics(statistics:statistics)
            healthDataArray.append(healthData)
        }
        
        return healthDataArray
    }
}
