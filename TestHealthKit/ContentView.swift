//
//  ContentView.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/07/22.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var readyToNavigate : Bool = false
    let healthKitController = HealthKitController()
    
    var body: some View {
        NavigationStack {
            VStack (alignment: .center, spacing: 20) {
                Text("Welcome to MyApp")
                    .font(.title)
                
                Button {
                    Task {
                        let sharedTypes = Set(await healthKitController.shareDataTypes())
                        let readTypes = Set(await healthKitController.readDataTypes())
                    
                        let result = await healthKitController.requestHealthDataAccessIfNeeded(toShare: sharedTypes, read: readTypes)
                        if result {
                            readyToNavigate = true
                            print("HealthKit authorization is succeeded.")
                        }
                    }
                } label: {
                    Text("Start")
                }
            }
            .navigationDestination(isPresented: $readyToNavigate) {
                HealthDataTabView()
            }
        }
    }
}

#Preview {
    ContentView()
}
