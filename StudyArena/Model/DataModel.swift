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
    
    // ⭐️ レベルに応じた投稿文字数制限を計算
    var postCharacterLimit: Int {
        // レベル1で5文字、レベル100で40文字
        // 計算式: 5 + (レベル-1) * 35 / 99
        let baseLimit = 5
        let maxBonus = 35
        let clampedLevel = min(100, max(1, level)) // 1-100の範囲に制限
        let bonus = Int(Double(clampedLevel - 1) * Double(maxBonus) / 99.0)
        return baseLimit + bonus
    }
    
    // ⭐️ 次の文字数増加までのレベル差を計算
    var levelsUntilNextCharacterIncrease: Int? {
        guard level < 100 else { return nil }
        
        let currentLimit = postCharacterLimit
        
        // 次に文字数が増えるレベルを探す
        for nextLevel in (level + 1)...100 {
            var nextUser = User(
                id: id,
                nickname: nickname,
                level: nextLevel,
                experience: experience,
                totalStudyTime: totalStudyTime,
                unlockedPersonIDs: unlockedPersonIDs
            )
            nextUser.rank = rank
            
            if nextUser.postCharacterLimit > currentLimit {
                return nextLevel - level
            }
        }
        
        return nil
    }
    
    // ⭐️ 文字数マイルストーン情報
    static let characterMilestones: [(level: Int, characters: Int)] = [
        (1, 5),
        (5, 6),
        (10, 8),
        (15, 10),
        (20, 12),
        (25, 14),
        (30, 16),
        (35, 17),
        (40, 19),
        (45, 21),
        (50, 23),
        (55, 24),
        (60, 26),
        (65, 28),
        (70, 30),
        (75, 31),
        (80, 33),
        (85, 35),
        (90, 37),
        (95, 38),
        (100, 40)
    ]
    
    // ⭐️ 次のマイルストーンまでの情報を取得
    func nextCharacterMilestone() -> (level: Int, characters: Int, levelsToGo: Int)? {
        for milestone in User.characterMilestones {
            if level < milestone.level {
                return (
                    level: milestone.level,
                    characters: milestone.characters,
                    levelsToGo: milestone.level - level
                )
            }
        }
        return nil
    }
    
    // ⭐️ 現在のトロフィー
    var currentTrophy: Trophy? {
        return Trophy.from(level: level)
    }
    
    // ⭐️ 次のトロフィー情報
    var nextTrophyInfo: (trophy: Trophy, levelRequired: Int, levelsToGo: Int)? {
        let trophyMilestones: [(level: Int, trophy: Trophy)] = [
            (8, .bronze(.II)),
            (15, .bronze(.III)),
            (21, .silver(.I)),
            (31, .silver(.II)),
            (41, .silver(.III)),
            (51, .gold(.I)),
            (66, .gold(.II)),
            (86, .gold(.III)),
            (101, .platinum(.I)),
            (116, .platinum(.II)),
            (136, .platinum(.III)),
            (151, .diamond(.I)),
            (166, .diamond(.II)),
            (186, .diamond(.III)),
            (201, .master(.I)),
            (251, .master(.II)),
            (301, .master(.III))
        ]
        
        for milestone in trophyMilestones {
            if level < milestone.level {
                return (
                    trophy: milestone.trophy,
                    levelRequired: milestone.level,
                    levelsToGo: milestone.level - level
                )
            }
        }
        return nil
    }
}
