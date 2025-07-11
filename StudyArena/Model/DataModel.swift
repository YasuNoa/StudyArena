// DataModel.swift

import Foundation
import FirebaseFirestore

// MARK: - User Model
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    
    var nickname: String = "挑戦者"  // デフォルト値を設定
    var level: Int = 1
    var experience: Double = 0
    var totalStudyTime: TimeInterval = 0
    var unlockedPersonIDs: [String] = []
    
    // ランキング表示時にViewModel側で設定する一時的なプロパティ
    var rank: Int? = nil
    
    // Firestoreに保存しないプロパティを定義
    enum CodingKeys: String, CodingKey {
        // ⚠️ 重要: idを削除！@DocumentIDは自動的に処理される
        case level
        case experience
        case totalStudyTime
        case nickname
        case unlockedPersonIDs
        // rankはCodingKeysに含めない（一時的なプロパティのため）
    }
    
    var experienceForNextLevel: Double {
        // レベルが上がるごとに必要経験値が増えるように調整
        return Double(level * 100 + Int(pow(Double(level), 1.5) * 50))
    }
}
