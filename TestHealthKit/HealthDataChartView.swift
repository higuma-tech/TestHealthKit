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

struct ToyShape: Identifiable {
    var type: String
    var count: Double
    var id = UUID()
}

var data: [ToyShape] = [
    .init(type: "Cube", count: 5),
    .init(type: "Sphere", count: 4),
    .init(type: "Pyramid", count: 4)
]

struct HealthDataChartView: View {
    @State var stepsData:[HealthDataType] = []
    @State var distanceWalkingRunningData:[HealthDataType] = []
    @State var sixMinuteWalkTestDistanceData:[HealthDataType] = []

    var body: some View {
        VStack {
            GroupBox("Steps") {
                HStack {
                    Text("Steps per day")
                    Spacer()
                }
                Chart(stepsData) {element in
                    BarMark(
                        x: .value("Day", element.dayOfWeek),
                        y: .value("Count", element.value)
                    )
                }
            }
            .onAppear {
                HealthData.StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.stepCount) {collection in
                    let healthDataArray = HealthData.getValueAndDayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.stepCount, collection: collection)
                    
                    DispatchQueue.main.async {
                        stepsData = healthDataArray
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
                        x: .value("Shape Type", element.dayOfWeek),
                        y: .value("Total Count", element.value)
                    )
                }
            }
            .onAppear() {
                HealthData.StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning) {collection in
                    let healthDataArray = HealthData.getValueAndDayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning, collection: collection)
                    
                    DispatchQueue.main.async {
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
                        x: .value("Shape Type", element.dayOfWeek),
                        y: .value("Total Count", element.value)
                    )
                }
            }
            .onAppear() {
                HealthData.StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance) {collection in
                    let healthDataArray = HealthData.getValueAndDayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance, collection: collection)
                    
                    DispatchQueue.main.async {
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
