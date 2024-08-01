//
//  HealthDataCollection.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/07/31.
//

import SwiftUI
import HealthKit

struct HealthDataCollection: View {
    @State var labelTextSteps = "Shown here"
    @State var labelTextDistanceWalkingRunning = "Shown here"
    @State var labelTextSixMinuteWalkTestDistance = "Shown here"
    @State var listTextSteps:[[String]] = []
    @State var listTextDistanceWalkingRunning:[[String]] = []
    @State var listTextSixMinuteWalkTestDistance:[[String]] = []
    @State var listTextStepsDate:[String] = []
    
    let healthStore = HKHealthStore()
    let allTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
    
    var body: some View {
        
        List {
            Section(header:Text("Steps")) {
                ForEach(listTextSteps, id: \.self) {item in
                    HStack {
                        Text(item[0])   // steps
                        Spacer()
                        Text(item[1])   // date
                    }
                }
            }
            .onAppear{
                StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.stepCount) {collection in
                    let textArray = getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.stepCount, collection: collection)
                    
                    DispatchQueue.main.async {
                        self.listTextSteps = textArray
                    }
                }
            }
            
            Section(header:Text("distanceWalkingRunning")) {
                ForEach(listTextDistanceWalkingRunning, id: \.self) {item in
                    HStack {
                        Text(item[0])
                        Spacer()
                        Text(item[1])
                    }
                }
            }
            .onAppear{
                StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning) {collection in
                    let textArray = getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning, collection: collection)
                    
                    DispatchQueue.main.async {
                        self.listTextDistanceWalkingRunning = textArray
                    }
                }
            }
            
            Section(header:Text("sixMinuteWalkTestDistance")) {
                ForEach(listTextSixMinuteWalkTestDistance, id: \.self) {item in
                    HStack {
                        Text(item[0])
                        Spacer()
                        Text(item[1])
                    }
                }
            }
            .onAppear{
                StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance) {collection in
                    let textArray = getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance, collection: collection)
                    
                    DispatchQueue.main.async {
                        self.listTextSixMinuteWalkTestDistance = textArray
                    }
                }
            }
        }
        
        Button(action: {
            StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.stepCount) {collection in
                let textArray = getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.stepCount, collection: collection)
                
                DispatchQueue.main.async {
                    self.listTextSteps = textArray
                }
            }
            
            StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning) {collection in
                let textArray = getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning, collection: collection)
                
                DispatchQueue.main.async {
                    self.listTextDistanceWalkingRunning = textArray
                }
            }
            
            StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance) {collection in
                let textArray = getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance, collection: collection)
                
                DispatchQueue.main.async {
                    self.listTextSixMinuteWalkTestDistance = textArray
                }
            }
            
        }) {
            Text("Update")
        }
        .frame(maxWidth: .infinity, minHeight:44.0)
        .accentColor(Color.white)
        .background(Color.blue.ignoresSafeArea(edges: .bottom))
    }
    
    private func getStepCount(operation:@escaping((_ stepCount:Int)->Void)) -> Void {
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
        self.healthStore.execute(query)
    }
    
    private func StatisticsQueryForHKQuantityTypeIdentifier(identifier:HKQuantityTypeIdentifier, operation:@escaping((_ sum:HKQuantity?)->Void)) -> Void {
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
        self.healthStore.execute(query)
    }
    
    private func StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier:HKQuantityTypeIdentifier, operation:@escaping((_ collection:HKStatisticsCollection?)->Void)) -> Void {
        
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
        
        healthStore.execute(query)
    }
    
    private func getStringArrayFromHKStatisticsCollection(identifier:HKQuantityTypeIdentifier, collection: HKStatisticsCollection?) -> [[String]] {
        
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
            print("stop:", stop.pointee)
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
    
    private func getStartDateFromHKStatistics(statistics:HKStatistics) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let startDateString = dateFormatter.string(from: statistics.startDate)
        
        return startDateString
    }
}


#Preview {
    DataCollection()
}
