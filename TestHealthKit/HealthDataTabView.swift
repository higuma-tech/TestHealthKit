//
//  HealthDataTabView.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/08/06.
//

import SwiftUI

struct HealthDataTabView: View {
    @State var selection = 2
    
    var body: some View {
        TabView(selection: $selection) {
            HealthDataCollectionView().tabItem {
                VStack {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
            }
            
            HealthDataChartView().tabItem {
                VStack {
                    Image(systemName: "chart.bar")
                    Text("Chart")
                }
            }
        }
    }
}

#Preview {
    HealthDataTabView()
}
