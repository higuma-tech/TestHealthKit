//
//  DataCollection.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/07/25.
//

import SwiftUI
import HealthKit

struct DataCollection: View {
    @State var labelTextSteps = "Shown here"
    @State var labelTextDistanceWalkingRunning = "Shown here"
    @State var labelTextSixMinuteWalkTestDistance = "Shown here"
    let healthStore = HKHealthStore()
    let allTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
    
    var body: some View {
        Text(labelTextSteps)
            .font(.largeTitle)
            .padding(.bottom)
            .onAppear {
                StatisticsQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.stepCount) { sum in
                    let stepCount = Int((sum?.doubleValue(for: HKUnit.count()))!)
                    print("onApper stepCount: ", stepCount)
                    DispatchQueue.main.async {
                        self.labelTextSteps = String(stepCount) + " steps"
                    }
                }
            }
        
        Text(labelTextDistanceWalkingRunning)
            .font(.largeTitle)
            .padding(.bottom)
            .onAppear {
                StatisticsQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning) { sum in
                    let distanceWalkingRunning = Int((sum?.doubleValue(for: HKUnit.meter()))!)
                    print("onApper distanceWalkingRunning: ", distanceWalkingRunning)
                    DispatchQueue.main.async {
                        self.labelTextDistanceWalkingRunning = String(distanceWalkingRunning) + " m"
                    }
                }
            }
        
        Text(labelTextSixMinuteWalkTestDistance)
            .font(.largeTitle)
            .padding(.bottom)
            .onAppear {
                StatisticsQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance) { sum in
                    let sixMinuteWalkTestDistance = Int((sum?.doubleValue(for: HKUnit.meter()))!)
                    print("onApper sixMinuteWalkTestDistance: ", sixMinuteWalkTestDistance)
                    DispatchQueue.main.async {
                        self.labelTextSixMinuteWalkTestDistance = String(sixMinuteWalkTestDistance) + " m"
                    }
                }
            }
        
        Button(action: {
            StatisticsQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.stepCount) { sum in
                let stepCount = Int((sum?.doubleValue(for: HKUnit.count()))!)
                print("onApper stepCount: ", stepCount)
                DispatchQueue.main.async {
                    self.labelTextSteps = String(stepCount) + " steps"
                }
            }
            
            StatisticsQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning) { sum in
                let distanceWalkingRunning = Int((sum?.doubleValue(for: HKUnit.meter()))!)
                print("onApper distanceWalkingRunning: ", distanceWalkingRunning)
                DispatchQueue.main.async {
                    self.labelTextDistanceWalkingRunning = String(distanceWalkingRunning) + " m"
                }
            }
            
            StatisticsQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance) { sum in
                let sixMinuteWalkTestDistance = Int((sum?.doubleValue(for: HKUnit.meter()))!)
                print("onApper sixMinuteWalkTestDistance: ", sixMinuteWalkTestDistance)
                DispatchQueue.main.async {
                    self.labelTextSixMinuteWalkTestDistance = String(sixMinuteWalkTestDistance) + " m"
                }
            }
        }) {
            Text("Update")
        }
        .padding()
        .accentColor(Color.white)
        .background(Color.blue)
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
            options = .mostRecent
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
            case .mostRecent:
                result = statistics.mostRecentQuantity()
            default:
                result = statistics.mostRecentQuantity()
            }
            operation(result)
        }
        self.healthStore.execute(query)
    }
}

#Preview {
    DataCollection()
}
