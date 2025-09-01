//
//  MBTIPieChartView.swift
//  StudyArena
//
//  Created by 田中正造 on 23/08/2025.
//


import Charts
import SwiftUI

struct MBTIPieChartView: View {
    let mbtiData: [MBTIStatData]
    
    var body: some View {
        Chart(mbtiData) { item in
            SectorMark(
                angle: .value("Time", item.totalTime),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Type", item.mbtiType))
            .cornerRadius(5)
        }
        .frame(height: 300)
        .chartLegend(position: .bottom, spacing: 10)
        .chartBackground { chartProxy in
            // 中央にラベル表示
            GeometryReader { geometry in
                VStack {
                    Text("MBTI別")
                    Text("学習時間")
                }
                .position(x: geometry.frame(in: .local).midX,
                         y: geometry.frame(in: .local).midY)
            }
        }
    }
}