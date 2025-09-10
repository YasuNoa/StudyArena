//
//  UserStatusCard.swift - レイアウト修正版
//  productene
//

import SwiftUI

struct UserStatusCard: View {
    let user: User
    @EnvironmentObject var viewModel: MainViewModel
    
    // 現在のトロフィー情報を取得
    var trophyInfo: (color: Color, icon: String, rank: String?) {
        if let trophy = user.currentTrophy {
            let rankString: String
            switch trophy {
            case .bronze(let rank), .silver(let rank), .gold(let rank), .platinum(let rank), .diamond(let rank):
                rankString = rank.rawValue
            }
            return (trophy.color, trophy.icon, rankString)
        }
        // デフォルト（レベル1未満の場合）
        return (Color.gray, "questionmark.circle", nil)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 左側：トロフィーとローマ数字ランク
            VStack(spacing: 2) {
                // ローマ数字ランク（トロフィーの上）
                if let rank = trophyInfo.rank {
                    Text(rank)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(trophyInfo.color)
                        .frame(height: 12)
                } else {
                    Spacer()
                        .frame(height: 12)
                }
                
                // トロフィーアイコン
                Image(systemName: trophyInfo.icon)
                    .font(.system(size: 32))
                    .foregroundColor(trophyInfo.color.opacity(0.8))
                    .shadow(color: trophyInfo.color.opacity(0.3), radius: 3)
            }
            .frame(width: 48)
            
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
            
            // 右側：レベルと経験値情報
            VStack(alignment: .trailing, spacing: 4) {
                // レベル表示（経験値バーの左上）
                HStack(spacing: 4) {
                    Text("Lv.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(user.level)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // 経験値プログレスバー
                VStack(alignment: .trailing, spacing: 2) {
                    ProgressView(value: user.experience, total: user.experienceForNextLevel)
                        .tint(.yellow)
                        .frame(width: 100, height: 3)
                        .background(
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(.white.opacity(0.1))
                        )
                    
                    // 経験値テキスト
                    Text(formatExperience(current: user.experience, total: user.experienceForNextLevel))
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.5))
                    
                    // 次のレベルまで
                    Text("次Lvまで\(formatNumber(user.experienceForNextLevel - user.experience))")
                        .font(.system(size: 7))
                        .foregroundColor(.green.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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
    
    // 数値フォーマット用のヘルパーメソッド
    private func formatNumber(_ value: Double) -> String {
        let intValue = Int(value)
        
        if intValue >= 1_000_000 {
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
            
            // レベル25のシルバーユーザー
            UserStatusCard(user: User(
                id: "2",
                nickname: "中級者花子",
                level: 25,
                experience: 5000,
                totalStudyTime: 100000
            ))
            .environmentObject(MainViewModel.mock)
            
            // レベル60のゴールドユーザー
            UserStatusCard(user: User(
                id: "3",
                nickname: "上級者次郎",
                level: 60,
                experience: 15000,
                totalStudyTime: 500000
            ))
            .environmentObject(MainViewModel.mock)
            
            // レベル180のダイヤモンドユーザー
            UserStatusCard(user: User(
                id: "4",
                nickname: "ダイヤモンド王",
                level: 180,
                experience: 80000,
                totalStudyTime: 5000000
            ))
            .environmentObject(MainViewModel.mock)
        }
        .padding()
    }
}
#endif
