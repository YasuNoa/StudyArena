//
//  TimelinePost.swift
//  StudyArena
//
//  Created by 田中正造 on 04/08/2025.
//

import Foundation
import FirebaseFirestore

// タイムラインアイテムのプロトコル
protocol TimelineItem {
    var timestamp: Date { get }
    var itemType: TimelineItemType { get }
}

enum TimelineItemType {
    case studyRecord(StudyRecord)
    case post(TimelinePost)
}

// タイムライン投稿のデータモデル
struct TimelinePost: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let nickname: String
    let content: String
    let timestamp: Date
    let level: Int
    var likeCount: Int? = 0  // いいね数
    var likedUserIds: [String]? = []  // いいねしたユーザーのID
    var studyDuration: TimeInterval?
    var linkedStudyRecordId: String?
    
    // Firestoreに保存するプロパティ
    enum CodingKeys: String, CodingKey {
        case userId
        case nickname
        case content
        case timestamp
        case level
        case likeCount
        case likedUserIds
        case studyDuration
        case linkedStudyRecordId
    }
    
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
    
    // 🔧 修正: 特定のユーザーがいいね済みかチェック
    func isLikedBy(userId: String) -> Bool {
        // 🚨 元のコード: return ((likedUserIds?.contains(userId)) != nil) // これは常にtrueになる
        // ✅ 修正版:
        return likedUserIds?.contains(userId) ?? false
    }
}
