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
    @State var listTextSteps:[HealthDataType] = []
    @State var listTextDistanceWalkingRunning:[HealthDataType] = []
    @State var listTextSixMinuteWalkTestDistance:[HealthDataType] = []
    @State var showSheet:Bool = false
    @State private var date:Date = Date()
    @State private var inputInt:Int = 0
    
    let healthKitController = HealthKitController()
    let healthStore = HKHealthStore()
    let allTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
    
    var body: some View {
        NavigationStack {
            Button {
                showSheet.toggle()
            } label: {
                Text("Add data")
            }
            .sheet(isPresented: $showSheet, onDismiss: didDismiss, content: {
                InputCountSheet()
            })
                        
            List {
                Section(header:Text("Steps")) {
                    ForEach(listTextSteps, id: \.self) {item in
                        HStack {
                            Text(item.valueString)  // steps
                            Spacer()
                            Text(item.dayString)  // date
                        }
                    }
                }
                .task {
                    let collection = await healthKitController.QueryStatisticsCollection(forIdentifier: .stepCount)
                    if let collection = collection {
                        let textArray = await healthKitController.getHealthDateFromHKStatisticsCollection(identifier: .stepCount, collection: collection)
                        
                        await MainActor.run {
                            self.listTextSteps = textArray
                        }
                    }
                }
                
                Section(header:Text("distanceWalkingRunning")) {
                    ForEach(listTextDistanceWalkingRunning, id: \.self) {item in
                        HStack {
                            Text(item.valueString)
                            Spacer()
                            Text(item.dayString)
                        }
                    }
                }
                .task {
                    let collection = await healthKitController.QueryStatisticsCollection(forIdentifier: .distanceWalkingRunning)
                    if let collection = collection {
                        let textArray = await healthKitController.getHealthDateFromHKStatisticsCollection(identifier: .distanceWalkingRunning, collection: collection)
                        
                        await MainActor.run {
                            self.listTextDistanceWalkingRunning = textArray
                        }
                    }
                }
                
                Section(header:Text("sixMinuteWalkTestDistance")) {
                    ForEach(listTextSixMinuteWalkTestDistance, id: \.self) {item in
                        HStack {
                            Text(item.valueString)
                            Spacer()
                            Text(item.dayString)
                        }
                    }
                }
                .task {
                    let collection = await healthKitController.QueryStatisticsCollection(forIdentifier: .sixMinuteWalkTestDistance)
                    if let collection = collection {
                        let textArray = await healthKitController.getHealthDateFromHKStatisticsCollection(identifier: .sixMinuteWalkTestDistance, collection: collection)
                        
                        await MainActor.run {
                            self.listTextSixMinuteWalkTestDistance = textArray
                        }
                    }
                }
            }
            .navigationTitle("Health Data")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func addSteps() {
        withAnimation {
        }
    }
    
    // didDismiss is called when the sheet is dismissed. It fetches data in the HealthStore.
    private func didDismiss() {
        Task {
            let collectionStepCount = await healthKitController.QueryStatisticsCollection(forIdentifier: .stepCount)
            if let collection = collectionStepCount {
                let textArray = await healthKitController.getHealthDateFromHKStatisticsCollection(identifier: .stepCount, collection: collection)
                
                await MainActor.run {
                    self.listTextSteps = textArray
                }
            }
                
            let collectionDistanceWalkingRunning = await healthKitController.QueryStatisticsCollection(forIdentifier: .distanceWalkingRunning)
            if let collection = collectionDistanceWalkingRunning {
                let textArray = await healthKitController.getHealthDateFromHKStatisticsCollection(identifier: .distanceWalkingRunning, collection: collection)
                
                await MainActor.run {
                    self.listTextDistanceWalkingRunning = textArray
                }
            }
                
            let collectionSixMinuteWalkTestDistance = await healthKitController.QueryStatisticsCollection(forIdentifier: .sixMinuteWalkTestDistance)
            if let collection = collectionSixMinuteWalkTestDistance {
                let textArray = await healthKitController.getHealthDateFromHKStatisticsCollection(identifier: .sixMinuteWalkTestDistance, collection: collection)
                
                await MainActor.run {
                    self.listTextSixMinuteWalkTestDistance = textArray
                }
            }
        }
    }

/*
    private func updateTextsInView(forIdentifier identifier:HKQuantityTypeIdentifier, textArray: inout [[String]]) async {
        let collection = await healthKitController.QueryStatisticsCollection(forIdentifier: identifier)
        if let collection = collection {
            let tempTextArray = healthKitController.getHealthDateFromHKStatisticsCollection(identifier: identifier, collection: collection)
            
            await MainActor.run {
                self.textArray = tempTextArray
            }
        }
    }
*/
}

struct InputCountSheet: View {
    @State private var dateSteps:Date = Date()
    @State private var valueSteps:Int = 0
    @State private var dateDistanceWalkingRunning:Date = Date()
    @State private var valueDistanceWalkingRunning:Double = 0
    @State private var dateSixMinuteWalkingDistance:Date = Date()
    @State private var valueSixMinuteWalkingDistance:Double = 0
    @Environment(\.dismiss) private var dismiss

    let healthKitController = HealthKitController()
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("STEPS")) {
                    DatePicker ("Date", selection: $dateSteps, displayedComponents: .date)
                    DatePicker ("Time", selection: $dateSteps, displayedComponents: .hourAndMinute)
                    HStack {
                        Text("Steps")
                        TextField("Steps", value: $valueSteps, format: .number)
                    }
                    .multilineTextAlignment(.trailing)
                }
                
                Section(header: Text("DISTANCEWALKINGRUNNING")) {
                    DatePicker ("Date", selection: $dateDistanceWalkingRunning, displayedComponents: .date)
                    DatePicker ("Time", selection: $dateDistanceWalkingRunning, displayedComponents: .hourAndMinute)
                    HStack {
                        Text("Distance")
                        TextField("Distance", value: $valueDistanceWalkingRunning, format: .number)
                        .multilineTextAlignment(.trailing)
                        Text("m")
                    }
                }
                
                Section(header: Text("SIXMINUTEWALKTESTDISTANCE")) {
                    DatePicker ("Date", selection: $dateSixMinuteWalkingDistance, displayedComponents: .date)
                    DatePicker ("Time", selection: $dateSixMinuteWalkingDistance, displayedComponents: .hourAndMinute)
                    HStack {
                        Text("Distance")
                        TextField("Distance", value: $valueSixMinuteWalkingDistance, format: .number)
                        .multilineTextAlignment(.trailing)
                        Text("m")
                    }
                }
            }
            .navigationTitle("Manual Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 ToolbarItem(placement: .topBarLeading) {
                    Button {
                        print("cancel")
                        dismiss()
                    } label: {
                        Text("cancel")
                    }
                } 

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        print("add")
                        Task {
                            let _ = await healthKitController.saveToHKStatistics(quantityTypeIdentifier:.stepCount, value: Double(valueSteps), date: dateSteps)
                            
                            let _ = await healthKitController.saveToHKStatistics(quantityTypeIdentifier: .distanceWalkingRunning, value: valueDistanceWalkingRunning, date: dateDistanceWalkingRunning)
                            
                            let _ = await healthKitController.saveToHKStatistics(quantityTypeIdentifier: .sixMinuteWalkTestDistance, value:valueSixMinuteWalkingDistance, date: dateSixMinuteWalkingDistance)
                        }
                        dismiss()
                    } label: {
                        Text("add")
                    }
                }
            }
        }
    }
}

#Preview {
    HealthDataCollectionView()
}
