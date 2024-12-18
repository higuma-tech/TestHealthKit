//
//  HealthDataChartView.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/08/06.
//

import SwiftUI
import Charts
import Foundation
import HealthKit

struct HealthDataDummy : Identifiable {
    var dayOfWeekString: String
    var value: Double
    var id = UUID()
}

var healthDataDummy: [HealthDataDummy] = [
    .init(dayOfWeekString: "Thu", value: 0.0),
    .init(dayOfWeekString: "Fri", value: 100.0),
    .init(dayOfWeekString: "Sat", value: 200.0),
    .init(dayOfWeekString: "Sun", value: 300.0),
    .init(dayOfWeekString: "Mon", value: 400.0),
    .init(dayOfWeekString: "Tue", value: 500.0),
    .init(dayOfWeekString: "Wed", value: 600.0),
]

var healthDataDummy2: [HealthDataType] = [
    .init(value: 0.0, valueString: "0 steps", dayString: "2024/12/12", dayOfWeekString: "Thu"),
    .init(value: 100.0, valueString: "100 steps", dayString: "2024/12/13", dayOfWeekString: "Fri"),
    .init(value: 200.0, valueString: "200 steps", dayString: "2024/12/14", dayOfWeekString: "Sat"),
    .init(value: 300.0, valueString: "300 steps", dayString: "2024/12/15", dayOfWeekString: "Sun"),
    .init(value: 400.0, valueString: "400 steps", dayString: "2024/12/16", dayOfWeekString: "Mon"),
    .init(value: 500.0, valueString: "500 steps", dayString: "2024/12/17", dayOfWeekString: "Tue"),
    .init(value: 600.0, valueString: "600 steps", dayString: "2024/12/18", dayOfWeekString: "Wed"),
]

struct HealthDataChartView: View {
    @State private var stepsData:[HealthDataType] = []
    @State private var distanceWalkingRunningData:[HealthDataType] = []
    @State private var sixMinuteWalkTestDistanceData:[HealthDataType] = []
    @State private var stepsData2:[HealthDataType] = [
        .init(value: 0.0, valueString: "0 steps", dayString: "2024/12/12", dayOfWeekString: "Thu"),
        .init(value: 100.0, valueString: "100 steps", dayString: "2024/12/13", dayOfWeekString: "Fri"),
        .init(value: 200.0, valueString: "200 steps", dayString: "2024/12/14", dayOfWeekString: "Sat"),
        .init(value: 300.0, valueString: "300 steps", dayString: "2024/12/15", dayOfWeekString: "Sun"),
        .init(value: 400.0, valueString: "400 steps", dayString: "2024/12/16", dayOfWeekString: "Mon"),
        .init(value: 500.0, valueString: "500 steps", dayString: "2024/12/17", dayOfWeekString: "Tue"),
        .init(value: 600.0, valueString: "600 steps", dayString: "2024/12/18", dayOfWeekString: "Wed"),
    ]
    let healthKitController = HealthKitController()

    var body: some View {
        VStack {
            GroupBox("Steps") {
                HStack {
                    Text("Steps per day")
                    Spacer()
                }
                Chart {
                    ForEach(stepsData2) {element in
                        BarMark(
                            x: .value("Day", element.dayOfWeekString),
                            y: .value("Count", element.value)
                        )
                    }
                }
                .task {
                    let collection = await healthKitController.QueryStatisticsCollection(forIdentifier: .stepCount)
                    if let collection = collection {
                        let healthDataArray = await healthKitController.getHealthDateFromHKStatisticsCollection(identifier: .stepCount, collection: collection)
                        
                         await MainActor.run {
                             stepsData2 = healthDataArray
                         }
                    }
                }
            }

            GroupBox("Walking distance") {
                HStack {
                    Text("Walking distance per day in meter")
                    Spacer()
                }
                Chart(distanceWalkingRunningData) {element in
                    BarMark(
                        x: .value("Shape Type", element.dayOfWeekString),
                        y: .value("Total Count", element.value)
                    )
                }
            }
            .task() {
                let collection = await healthKitController.QueryStatisticsCollection(forIdentifier: .distanceWalkingRunning)
                if let collection = collection {
                    let healthDataArray = await healthKitController.getHealthDateFromHKStatisticsCollection(identifier: .distanceWalkingRunning, collection: collection)
                    
                    await MainActor.run {
                        distanceWalkingRunningData = healthDataArray
                    }
                }
            }

            
            GroupBox("Six minutes walk test distance") {
                HStack {
                    Text("Average of six mitutes walking distance per day in meter")
                    //Text("Average of six mitutes walking distance")
                    Spacer()
                }
               Chart(sixMinuteWalkTestDistanceData) {element in
                    BarMark(
                        x: .value("Shape Type", element.dayOfWeekString),
                        y: .value("Total Count", element.value)
                    )
                }
            }
            .task() {
                let collection = await healthKitController.QueryStatisticsCollection(forIdentifier: .sixMinuteWalkTestDistance)
                if let collection = collection {
                    let healthDataArray = await healthKitController.getHealthDateFromHKStatisticsCollection(identifier: .sixMinuteWalkTestDistance, collection: collection)
                    
                    await MainActor.run {
                        sixMinuteWalkTestDistanceData = healthDataArray
                    }
                }
            }
        }
    }
}

#Preview {
    HealthDataChartView()
}
