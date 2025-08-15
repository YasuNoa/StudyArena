//
//  Trophy.swift
//  StudyArena
//
//  トロフィーシステムの定義
//

import Foundation
import SwiftUI

// トロフィーの列挙型
enum Trophy: Codable, Equatable {
    case bronze(TrophyRank)
    case silver(TrophyRank)
    case gold(TrophyRank)
    case platinum(TrophyRank)
    case diamond(TrophyRank)
    case master(TrophyRank)
    
    enum TrophyRank: String, Codable {
        case I = "I"
        case II = "II"
        case III = "III"
    }
    
    // レベルから対応するトロフィーを取得
    static func from(level: Int) -> Trophy? {
        switch level {
        case 1...7:
            return .bronze(.I)
        case 8...14:
            return .bronze(.II)
        case 15...20:
            return .bronze(.III)
        case 21...30:
            return .silver(.I)
        case 31...40:
            return .silver(.II)
        case 41...50:
            return .silver(.III)
        case 51...65:
            return .gold(.I)
        case 66...85:
            return .gold(.II)
        case 86...100:
            return .gold(.III)
        case 101...115:
            return .platinum(.I)
        case 116...135:
            return .platinum(.II)
        case 136...150:
            return .platinum(.III)
        case 151...165:
            return .diamond(.I)
        case 166...185:
            return .diamond(.II)
        case 186...200:
            return .diamond(.III)
        case 201...250:
            return .master(.I)
        case 251...300:
            return .master(.II)
        case 301...:
            return .master(.III)
        default:
            return nil
        }
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
        }
    }
}
