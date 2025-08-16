// DataModel.swift - レベル10000対応版

import Foundation
import FirebaseFirestore
import SwiftUI

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
        case level
        case experience
        case totalStudyTime
        case nickname
        case unlockedPersonIDs
    }
    
    // MARK: - 🎯 必要経験値の計算（レベル10000対応）
    var experienceForNextLevel: Double {
        // 対数的に増加する式：基本値 + レベルの1.8乗
        // レベル100で約8,500 EXP、レベル1000で約250,000 EXP、レベル10000で約6,300,000 EXP
        let base = Double(level * 50)
        let exponential = pow(Double(level), 1.8) * 10
        return base + exponential
    }
    
    // MARK: - 📝 投稿文字数制限の計算（レベル10000対応）
    var postCharacterLimit: Int {
        // 対数関数を使った非線形増加
        // レベル1で5文字、レベル100で約50文字、レベル1000で約150文字、レベル10000で約300文字
        let baseLimit = 5.0
        let logValue = log10(Double(level) + 1) // +1で0除算を防ぐ
        let multiplier = 25.0 // 成長率の調整
        let limit = baseLimit + (logValue * multiplier * pow(Double(level), 0.15))
        return min(500, Int(limit)) // 最大500文字で制限
    }
    
    // MARK: - ❤️ いいね回数制限の計算（レベル10000対応）
    var dailyLikeLimit: Int {
        // 平方根ベースの非線形増加
        // レベル1で3回、レベル100で約50回、レベル1000で約250回、レベル10000で約800回
        let base = 3.0
        let sqrtValue = sqrt(Double(level))
        let logBonus = log10(Double(level) + 1) * 10
        let limit = base + (sqrtValue * 5) + logBonus
        return min(1000, Int(limit)) // 最大1000回で制限
    }
    
    // MARK: - 🏆 現在のトロフィー（レベル10000対応）
    var currentTrophy: Trophy? {
        return Trophy.from(level: level)
    }
    
    // MARK: - 次のトロフィー情報
    var nextTrophyInfo: (trophy: Trophy, levelRequired: Int, levelsToGo: Int)? {
        guard let currentTrophy = self.currentTrophy else { return nil }
        
        // 現在のトロフィーから次のトロフィーのレベルを計算
        let nextLevel = Trophy.getNextTrophyLevel(currentLevel: level)
        
        if let nextLevel = nextLevel,
           let nextTrophy = Trophy.from(level: nextLevel) {
            return (
                trophy: nextTrophy,
                levelRequired: nextLevel,
                levelsToGo: nextLevel - level
            )
        }
        
        return nil
    }
    
    // MARK: - 文字数マイルストーン情報（動的計算版）
    static func getCharacterMilestones() -> [(level: Int, chars: Int)] {
        var milestones: [(level: Int, chars: Int)] = []
        
        // 対数的にマイルストーンを設定
        let checkpoints = [1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000]
        
        for checkpoint in checkpoints {
            var tempUser = User(level: checkpoint)
            milestones.append((level: checkpoint, chars: tempUser.postCharacterLimit))
        }
        
        return milestones
    }
    
    // MARK: - いいねマイルストーン情報（動的計算版）
    static func getLikeMilestones() -> [(level: Int, likes: Int)] {
        var milestones: [(level: Int, likes: Int)] = []
        
        // 対数的にマイルストーンを設定
        let checkpoints = [1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000]
        
        for checkpoint in checkpoints {
            var tempUser = User(level: checkpoint)
            milestones.append((level: checkpoint, likes: tempUser.dailyLikeLimit))
        }
        
        return milestones
    }
}

// MARK: - 🏆 Trophy System（レベル10000対応）
enum Trophy: Codable, Equatable {
    case bronze(TrophyRank)
    case silver(TrophyRank)
    case gold(TrophyRank)
    case platinum(TrophyRank)
    case diamond(TrophyRank)
    case master(TrophyRank)
    case grandmaster(TrophyRank)  // 新規追加
    case legend(TrophyRank)       // 新規追加
    case mythic(TrophyRank)       // 新規追加
    case eternal(TrophyRank)      // 新規追加
    
    enum TrophyRank: String, Codable {
        case I = "I"
        case II = "II"
        case III = "III"
    }
    
    // レベルから対応するトロフィーを取得（対数的スケーリング）
    static func from(level: Int) -> Trophy? {
        // 対数的にトロフィーの境界を設定
        // 各ティアは前のティアの約2.5倍のレベル幅を持つ
        
        switch level {
        case 1...10:
            return level <= 3 ? .bronze(.I) : level <= 6 ? .bronze(.II) : .bronze(.III)
        case 11...30:
            return level <= 17 ? .silver(.I) : level <= 23 ? .silver(.II) : .silver(.III)
        case 31...75:
            return level <= 45 ? .gold(.I) : level <= 60 ? .gold(.II) : .gold(.III)
        case 76...175:
            return level <= 108 ? .platinum(.I) : level <= 141 ? .platinum(.II) : .platinum(.III)
        case 176...400:
            return level <= 250 ? .diamond(.I) : level <= 325 ? .diamond(.II) : .diamond(.III)
        case 401...900:
            return level <= 566 ? .master(.I) : level <= 733 ? .master(.II) : .master(.III)
        case 901...2000:
            return level <= 1300 ? .grandmaster(.I) : level <= 1650 ? .grandmaster(.II) : .grandmaster(.III)
        case 2001...4500:
            return level <= 2833 ? .legend(.I) : level <= 3666 ? .legend(.II) : .legend(.III)
        case 4501...10000:
            return level <= 6334 ? .mythic(.I) : level <= 8167 ? .mythic(.II) : .mythic(.III)
        case 10001...:
            // レベル10000以降は全てEternal
            let subLevel = (level - 10001) / 5000
            return subLevel == 0 ? .eternal(.I) : subLevel == 1 ? .eternal(.II) : .eternal(.III)
        default:
            return nil
        }
    }
    
    // 次のトロフィーレベルを取得
    static func getNextTrophyLevel(currentLevel: Int) -> Int? {
        let milestones = [
            3, 6, 10,         // Bronze
            17, 23, 30,       // Silver
            45, 60, 75,       // Gold
            108, 141, 175,    // Platinum
            250, 325, 400,    // Diamond
            566, 733, 900,    // Master
            1300, 1650, 2000, // Grandmaster
            2833, 3666, 4500, // Legend
            6334, 8167, 10000,// Mythic
            15000, 20000      // Eternal
        ]
        
        for milestone in milestones {
            if currentLevel < milestone {
                return milestone
            }
        }
        
        // レベル20000以降は5000刻み
        if currentLevel >= 20000 {
            return ((currentLevel / 5000) + 1) * 5000
        }
        
        return nil
    }
    
    // 表示名
    var displayName: String {
        switch self {
        case .bronze(let rank):
            return "ブロンズ \(rank.rawValue)"
        case .silver(let rank):
            return "シルバー \(rank.rawValue)"
        case .gold(let rank):
            return "ゴールド \(rank.rawValue)"
        case .platinum(let rank):
            return "プラチナ \(rank.rawValue)"
        case .diamond(let rank):
            return "ダイヤモンド \(rank.rawValue)"
        case .master(let rank):
            return "マスター \(rank.rawValue)"
        case .grandmaster(let rank):
            return "グランドマスター \(rank.rawValue)"
        case .legend(let rank):
            return "レジェンド \(rank.rawValue)"
        case .mythic(let rank):
            return "ミシック \(rank.rawValue)"
        case .eternal(let rank):
            return "エターナル \(rank.rawValue)"
        }
    }
    
    // アイコン
    var icon: String {
        switch self {
        case .bronze:
            return "shield.fill"
        case .silver:
            return "shield.lefthalf.filled"
        case .gold:
            return "crown.fill"
        case .platinum:
            return "star.circle.fill"
        case .diamond:
            return "rhombus.fill"
        case .master:
            return "flame.fill"
        case .grandmaster:
            return "bolt.circle.fill"
        case .legend:
            return "sparkles"
        case .mythic:
            return "moon.stars.fill"
        case .eternal:
            return "infinity.circle.fill"
        }
    }
    
    // 色
    var color: Color {
        switch self {
        case .bronze:
            return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver:
            return Color(white: 0.7)
        case .gold:
            return Color.yellow
        case .platinum:
            return Color.cyan
        case .diamond:
            return Color.purple
        case .master:
            return Color.red
        case .grandmaster:
            return Color(red: 1.0, green: 0.5, blue: 0.0) // オレンジ
        case .legend:
            return Color(red: 0.0, green: 1.0, blue: 0.5) // エメラルド
        case .mythic:
            return Color(red: 0.8, green: 0.0, blue: 1.0) // バイオレット
        case .eternal:
            return Color(red: 1.0, green: 0.84, blue: 0.0) // ゴールデン
        }
    }
}

// MARK: - 計算式ヘルパー
extension User {
    // レベル到達までの累計経験値を計算
    static func totalExperienceForLevel(_ targetLevel: Int) -> Double {
        var total: Double = 0
        for level in 1..<targetLevel {
            let base = Double(level * 50)
            let exponential = pow(Double(level), 1.8) * 10
            total += base + exponential
        }
        return total
    }
    
    // 学習時間の目安を計算（1秒 = 1EXP）
    static func estimatedTimeForLevel(_ level: Int) -> String {
        let totalExp = totalExperienceForLevel(level)
        let hours = Int(totalExp) / 3600
        let minutes = (Int(totalExp) % 3600) / 60
        
        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "約\(days)日\(remainingHours)時間"
        } else if hours > 0 {
            return "約\(hours)時間\(minutes)分"
        } else {
            return "約\(minutes)分"
        }
    }
}
