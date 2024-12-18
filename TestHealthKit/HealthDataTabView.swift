//
//  HealthDataTabView.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/08/06.
//

import SwiftUI

struct HealthDataTabView: View {
    @State var selection = 1
    
    var body: some View {
        TabView(selection: $selection) {
            HealthDataCollectionView().tabItem {
                VStack {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
            }
            .tag(1)
            
            HealthDataChartView().tabItem {
                VStack {
                    Image(systemName: "chart.bar")
                    Text("Chart")
                }
            }
            .tag(2)
        }
    }
}

#Preview {
    HealthDataTabView()
}
