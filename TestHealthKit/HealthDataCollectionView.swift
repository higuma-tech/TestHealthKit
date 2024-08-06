//
//  HealthDataCollectionView.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/07/31.
//

import SwiftUI
import HealthKit

struct HealthDataCollectionView: View {
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
                    HealthData.StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.stepCount) {collection in
                        let textArray = HealthData.getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.stepCount, collection: collection)
                        
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
                    HealthData.StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning) {collection in
                        let textArray = HealthData.getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning, collection: collection)
                        
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
                    HealthData.StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance) {collection in
                        let textArray = HealthData.getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance, collection: collection)
                        
                        DispatchQueue.main.async {
                            self.listTextSixMinuteWalkTestDistance = textArray
                        }
                    }
                }
            }
            /*
            Button(action: {
                HealthData.StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.stepCount) {collection in
                    let textArray = HealthData.getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.stepCount, collection: collection)
                    
                    DispatchQueue.main.async {
                        self.listTextSteps = textArray
                    }
                }
                
                HealthData.StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning) {collection in
                    let textArray = HealthData.getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.distanceWalkingRunning, collection: collection)
                    
                    DispatchQueue.main.async {
                        self.listTextDistanceWalkingRunning = textArray
                    }
                }
                
                HealthData.StatisticsCollectionQueryForHKQuantityTypeIdentifier(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance) {collection in
                    let textArray = HealthData.getStringArrayFromHKStatisticsCollection(identifier: HKQuantityTypeIdentifier.sixMinuteWalkTestDistance, collection: collection)
                    
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
        */
        }
}


#Preview {
    HealthDataCollectionView()
}
