//
//  MBTIStatData.swift
//  StudyArena
//
//  Created by 田中正造 on 01/09/2025.
//

import Foundation

// MBTI統計データ構造体
struct MBTIStatData: Identifiable {
    let id = UUID()
    let mbtiType: String
    let totalTime: Double
    let userCount: Int
    let avgTime: Double
    
    init(mbtiType: String, totalTime: Double, userCount: Int, avgTime: Double) {
        self.mbtiType = mbtiType
        self.totalTime = totalTime
        self.userCount = userCount
        self.avgTime = avgTime
    }
}
