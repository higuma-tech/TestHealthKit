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
    @State var showSheet:Bool = false
    @State private var date:Date = Date()
    @State private var inputInt:Int = 0
    
    let healthStore = HKHealthStore()
    let allTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
    
    var body: some View {
        NavigationStack {
            Button {
                showSheet.toggle()
            } label: {
                Text("Add data")
            }
            .sheet(isPresented: $showSheet, content: {
                InputCountSheet()
            })
            
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
            .navigationTitle("Health Data")
            .navigationBarTitleDisplayMode(.inline)
/*            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addSteps) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            } 
 */
        }
    }
    
    private func addSteps() {
        withAnimation {
        }
    }
}

struct InputCountSheet: View {
    @State private var dateSteps:Date = Date()
    @State private var valueSteps:Int = 0
    @State private var dateDistanceWalkingRunning:Date = Date()
    @State private var valueDistanceWalkingRunning:Double = 0
    @State private var dateSixMinuteWalkingDistance:Date = Date()
    @State private var valueSixMinuteWalkingDistance:Int = 0
    @Environment(\.dismiss) private var dismiss

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
