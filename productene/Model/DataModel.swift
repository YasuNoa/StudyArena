// FileName: DataModels.swift

import Foundation
import FirebaseFirestore

// MARK: - GreatPerson Model
struct GreatPerson: Identifiable, Equatable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let imageName: String
    let skill: Skill
    
    static func == (lhs: GreatPerson, rhs: GreatPerson) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

struct Skill: Codable {
    let name: String
    let effect: SkillEffect
    let value: Double
}

enum SkillEffect: String, Codable, CaseIterable {
    case expBoost = "expBoost"
}

// MARK: - User Model
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var nickname: String = "挑戦者"
    var level: Int = 1
    var experience: Double = 0
    var totalStudyTime: TimeInterval = 0
    var unlockedPersonIDs: [String] = []
    
    // ランキング表示時にViewModel側で設定する一時的なプロパティ
    var rank: Int? = nil
    
    // Firestoreに保存しないプロパティを定義
    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case level
        case experience
        case totalStudyTime
        case unlockedPersonIDs
        // rankはCodingKeysに含めない（一時的なプロパティのため）
    }
    
    var experienceForNextLevel: Double {
        // レベルが上がるごとに必要経験値が増えるように調整
        return Double(level * 100 + Int(pow(Double(level), 1.5) * 50))
    }
}
