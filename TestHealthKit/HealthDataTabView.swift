//
//  HealthDataTabView.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/08/06.
//

import SwiftUI

enum Tabs: Equatable, Hashable {
    case list
    case chart
}

struct HealthDataTabView: View {
    @State var selection = Tabs.chart
    
    var body: some View {
        TabView(selection: $selection) {
            Tab("List", systemImage: "list.bullet", value: Tabs.list) {
                HealthDataCollectionView()
            }
            Tab("Chart", systemImage: "chart.bar", value: Tabs.chart) {
                HealthDataChartView()
            }
        }
    }
}

#Preview {
    HealthDataTabView()
}
