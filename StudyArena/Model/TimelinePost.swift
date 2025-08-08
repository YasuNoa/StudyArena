//
//  TimelinePost.swift
//  StudyArena
//
//  Created by 田中正造 on 04/08/2025.
//


import Foundation
import FirebaseFirestore

// タイムライン投稿のデータモデル
struct TimelinePost: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let nickname: String
    let content: String
    let timestamp: Date
    let level: Int
    
    // 表示用のフォーマット済み日付
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: timestamp)
    }
    
    // 相対的な時間表示（例：3分前、2時間前）
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}