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
    
    var body: some View {
        NavigationStack {
            VStack (alignment: .center, spacing: 20) {
                Text("Welcome to MyApp")
                    .font(.title)
                
                Button {
                    //Code here before changing the bool value
                    let sharedTypes = Set(HealthData.shareDataTypes)
                    let readTypes = Set(HealthData.readDataTypes)
                    HealthData.requestHealthDataAccessIfNeeded(toShare: sharedTypes, read: readTypes) {success in
                        if success == true {
                            readyToNavigate = true
                        }
                    }
                } label: {
                    Text("Start")
                }
            }
            .navigationDestination(isPresented: $readyToNavigate) {
                DataCollection()
            }
        }
    }
}

#Preview {
    ContentView()
}
