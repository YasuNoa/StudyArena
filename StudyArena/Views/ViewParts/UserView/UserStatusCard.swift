//
//  UserStatusCard.swift - レベル10000対応版
//  productene
//

import SwiftUI

struct UserStatusCard: View {
    let user: User
    @EnvironmentObject var viewModel: MainViewModel
    
    // 現在のトロフィー情報を取得
    var trophyInfo: (color: Color, icon: String) {
        if let trophy = user.currentTrophy {
            return (trophy.color, trophy.icon)
        }
        // デフォルト（レベル1未満の場合）
        return (Color.gray, "questionmark.circle")
    }
    
    // レベル数字のフォントサイズ（レベルに応じて調整）
    var levelFontSize: CGFloat {
        switch user.level {
        case 1...9:
            return 18
        case 10...99:
            return 16
        case 100...999:
            return 14
        case 1000...9999:
            return 12
        default: // 10000以上
            return 10
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 左側：トロフィーとレベル（完全に重なる）
            ZStack {
                // トロフィーアイコン（背景）
                Image(systemName: trophyInfo.icon)
                    .font(.system(size: 42))
                    .foregroundColor(trophyInfo.color.opacity(0.7))
                    .shadow(color: trophyInfo.color.opacity(0.3), radius: 5)
                
                // レベル番号（中央に完全オーバーレイ）
                Text("\(user.level)")
                    .font(.system(size: levelFontSize, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(width: 48, height: 48)
            
            // 中央：トロフィー名とニックネーム
            VStack(alignment: .leading, spacing: 2) {
                if let trophy = user.currentTrophy {
                    Text(trophy.displayName)
                        .font(.system(size: 11))
                        .foregroundColor(trophyInfo.color.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Text(user.nickname)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 右側：経験値情報（コンパクト版）
            VStack(alignment: .trailing, spacing: 4) {
                // 経験値プログレスバー（細く）
                ProgressView(value: user.experience, total: user.experienceForNextLevel)
                    .tint(.yellow)
                    .frame(width: 100, height: 3)
                    .background(
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(.white.opacity(0.1))
                    )
                
                // 経験値テキスト（大きな数値対応）
                Text(formatExperience(current: user.experience, total: user.experienceForNextLevel))
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
                
                // 次のレベルまで
                Text("次Lvまで\(formatNumber(user.experienceForNextLevel - user.experience))")
                    .font(.system(size: 8))
                    .foregroundColor(.green.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            trophyInfo.color.opacity(0.3),
                            trophyInfo.color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // 大きな数値を適切にフォーマット
    private func formatNumber(_ value: Double) -> String {
        let intValue = Int(value)
        
        if intValue >= 1_000_000_000 {
            return String(format: "%.1fB", Double(intValue) / 1_000_000_000)
        } else if intValue >= 1_000_000 {
            return String(format: "%.1fM", Double(intValue) / 1_000_000)
        } else if intValue >= 10_000 {
            return String(format: "%.1fK", Double(intValue) / 1_000)
        } else {
            return "\(intValue)"
        }
    }
    
    private func formatExperience(current: Double, total: Double) -> String {
        let currentStr = formatNumber(current)
        let totalStr = formatNumber(total)
        return "\(currentStr)/\(totalStr)"
    }
}

// レベルバッジコンポーネント（レベル10000対応版）
struct LevelBadge: View {
    let level: Int
    
    // レベルに応じた文字サイズを動的に計算
    var fontSize: CGFloat {
        switch level {
        case 1...9:
            return 16
        case 10...99:
            return 14
        case 100...999:
            return 12
        case 1000...9999:
            return 10
        default:
            return 8
        }
    }
    
    // レベルに応じた背景グラデーション（新トロフィーシステム対応）
    var badgeGradient: LinearGradient {
        if let trophy = Trophy.from(level: level) {
            let color = trophy.color
            return LinearGradient(
                colors: [color, color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // デフォルト
        return LinearGradient(
            colors: [Color.gray, Color.gray.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            // 背景の円
            Circle()
                .fill(badgeGradient)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            
            // レベル番号
            VStack(spacing: 0) {
                Text(formatLevelNumber(level))
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                if level < 10000 {
                    Text("Lv")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }
    
    private func formatLevelNumber(_ level: Int) -> String {
        if level >= 10000 {
            return "\(level / 1000)K"
        } else if level >= 1000 {
            return String(format: "%.1fK", Double(level) / 1000)
        } else {
            return "\(level)"
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 20) {
            // レベル5のブロンズユーザー
            UserStatusCard(user: User(
                id: "1",
                nickname: "初心者太郎",
                level: 5,
                experience: 250,
                totalStudyTime: 3600
            ))
            .environmentObject(MainViewModel.mock)
            
            // レベル100のゴールドユーザー
            UserStatusCard(user: User(
                id: "2",
                nickname: "中級者花子",
                level: 100,
                experience: 5000,
                totalStudyTime: 100000
            ))
            .environmentObject(MainViewModel.mock)
            
            // レベル1000のグランドマスター
            UserStatusCard(user: User(
                id: "3",
                nickname: "上級者次郎",
                level: 1000,
                experience: 150000,
                totalStudyTime: 5000000
            ))
            .environmentObject(MainViewModel.mock)
            
            // レベル5000のレジェンド
            UserStatusCard(user: User(
                id: "4",
                nickname: "伝説の人",
                level: 5000,
                experience: 800000,
                totalStudyTime: 50000000
            ))
            .environmentObject(MainViewModel.mock)
            
            // レベル10000のミシック
            UserStatusCard(user: User(
                id: "5",
                nickname: "神話級",
                level: 10000,
                experience: 2000000,
                totalStudyTime: 100000000
            ))
            .environmentObject(MainViewModel.mock)
        }
        .padding()
    }
}
#endif
