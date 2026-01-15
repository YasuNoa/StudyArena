// DataModel.swift - ダイヤモンドまでの報酬体系版

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
    var departments: [DepartmentMembership]? = []
    var primaryDepartmentId: String? = nil
    // User構造体に追加
    var dailyPostLimit: Int {
        switch level {
        case 1...49: return 1
        case 50...99: return 2
        case 100...499: return 3
        case 500...999: return 5
        default: return 10  // レベル1000以上
        }
    }
    var mbtiType: String? = nil  // MBTI型（16種類）
    
    // ランキング表示時にViewModel側で設定する一時的なプロパティ
    var rank: Int? = nil
    
    // Firestoreに保存しないプロパティを定義
    enum CodingKeys: String, CodingKey {
        case level
        case experience
        case totalStudyTime
        case nickname
        case unlockedPersonIDs
        case departments
        case primaryDepartmentId
        case mbtiType
    }
    
    // MARK: - 🎯 必要経験値の計算（現実的な成長版）
    var experienceForNextLevel: Double {
        // より緩やかな成長に調整
        let base = Double(level * 100)
        let exponential = pow(Double(level), 1.5) * 20
        return base + exponential
    }
    
    // MARK: - 📝 投稿文字数制限の計算（現実的版）
    var postCharacterLimit: Int {
        switch level {
        case 1...2:
            return 10   // 最初は10文字
        case 3...5:
            return 15
        case 6...10:
            return 20
        case 11...15:
            return 25
        case 16...20:
            return 30   // ブロンズ卒業時
        case 21...30:
            return 35
        case 31...40:
            return 40
        case 41...50:
            return 45
        case 51...60:
            return 50
        case 61...75:
            return 60   // ゴールド卒業時
        case 76...90:
            return 70
        case 91...110:
            return 80
        case 111...130:
            return 90
        case 131...150:
            return 100
        case 151...175:
            return 120  // プラチナ卒業時
        default:        // レベル176以上（ダイヤモンド）
            return 150  // 最大150文字で固定
        }
    }
    
    // MARK: - 文字数マイルストーン情報（トロフィー別版）
    static func getCharacterMilestones() -> [(level: Int, chars: Int)] {
        return [
            (level: 1, chars: 5),     // ブロンズI開始
            (level: 7, chars: 5),     // ブロンズII
            (level: 14, chars: 5),    // ブロンズIII
            (level: 21, chars: 10),   // シルバーI開始
            (level: 30, chars: 10),   // シルバーII
            (level: 40, chars: 10),   // シルバーIII
            (level: 51, chars: 15),   // ゴールドI開始
            (level: 65, chars: 15),   // ゴールドII
            (level: 80, chars: 15),   // ゴールドIII
            (level: 101, chars: 20),  // プラチナI開始
            (level: 125, chars: 20),  // プラチナII
            (level: 150, chars: 20),  // プラチナIII
            (level: 176, chars: 25),  // ダイヤモンド開始 - 最大値
        ]
    }
    
    // MARK: - 🏆 現在のトロフィー（ダイヤモンドまで版）
    var currentTrophy: Trophy? {
        return Trophy.from(level: level)
    }
    
    // MARK: - 次のトロフィー情報
    var nextTrophyInfo: (trophy: Trophy, levelRequired: Int, levelsToGo: Int)? {
        guard let currentTrophy = self.currentTrophy else { return nil }
        
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
}

// MARK: - 🏆 Trophy System（ダイヤモンドまで版）
enum Trophy: Codable, Equatable {
    case bronze(TrophyRank)
    case silver(TrophyRank)
    case gold(TrophyRank)
    case platinum(TrophyRank)
    case diamond(TrophyRank)
    
    enum TrophyRank: String, Codable {
        case I = "I"
        case II = "II"
        case III = "III"
    }
    
    // レベルから対応するトロフィーを取得（ダイヤモンドまで版）
    static func from(level: Int) -> Trophy? {
        switch level {
        case 1...20:
            return level <= 7 ? .bronze(.I) : level <= 14 ? .bronze(.II) : .bronze(.III)
        case 21...50:
            return level <= 30 ? .silver(.I) : level <= 40 ? .silver(.II) : .silver(.III)
        case 51...100:
            return level <= 65 ? .gold(.I) : level <= 80 ? .gold(.II) : .gold(.III)
        case 101...175:
            return level <= 125 ? .platinum(.I) : level <= 150 ? .platinum(.II) : .platinum(.III)
        case 176...:
            // レベル176以上は全てダイヤモンド
            return level <= 200 ? .diamond(.I) : level <= 250 ? .diamond(.II) : .diamond(.III)
        default:
            return nil
        }
    }
    
    // 次のトロフィーレベルを取得（ダイヤモンドまで版）
    static func getNextTrophyLevel(currentLevel: Int) -> Int? {
        let milestones = [
            7, 14, 20,        // Bronze
            30, 40, 50,       // Silver
            65, 80, 100,      // Gold
            125, 150, 175,    // Platinum
            200, 250, 300     // Diamond
        ]
        
        for milestone in milestones {
            if currentLevel < milestone {
                return milestone
            }
        }
        
        // レベル300以降は50刻み
        if currentLevel >= 300 {
            return ((currentLevel / 50) + 1) * 50
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
        }
    }
}

// MARK: - 計算式ヘルパー
extension User {
    // レベル到達までの累計経験値を計算
    static func totalExperienceForLevel(_ targetLevel: Int) -> Double {
        var total: Double = 0
        for level in 1..<targetLevel {
            let base = Double(level * 100)
            let exponential = pow(Double(level), 1.5) * 20
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

// MARK: - Notification Setting
struct NotificationSetting: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    var isEnabled: Bool
    var time: DateComponents? // 時間指定が必要な場合
}
