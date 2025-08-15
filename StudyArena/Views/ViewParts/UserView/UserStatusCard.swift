//
//  UserStatusCard.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

struct UserStatusCard: View {
    let user: User
    @EnvironmentObject var viewModel: MainViewModel
    
    // トロフィー情報をレベルから直接判定
    var trophyInfo: (color: Color, icon: String) {
        switch user.level {
        case 1...20:
            return (Color(red: 0.8, green: 0.5, blue: 0.2), "shield.fill")
        case 21...50:
            return (Color(white: 0.7), "shield.lefthalf.filled")
        case 51...100:
            return (Color.yellow, "crown.fill")
        case 101...150:
            return (Color.cyan, "star.circle.fill")
        case 151...200:
            return (Color.purple, "rhombus.fill")
        default:
            return (Color.red, "flame.fill")
        }
    }
    
    // レベルからトロフィー名を取得
    func getTrophyName(level: Int) -> String {
        switch level {
        case 1...7: return "ブロンズ I"
        case 8...14: return "ブロンズ II"
        case 15...20: return "ブロンズ III"
        case 21...30: return "シルバー I"
        case 31...40: return "シルバー II"
        case 41...50: return "シルバー III"
        case 51...65: return "ゴールド I"
        case 66...85: return "ゴールド II"
        case 86...100: return "ゴールド III"
        case 101...115: return "プラチナ I"
        case 116...135: return "プラチナ II"
        case 136...150: return "プラチナ III"
        case 151...165: return "ダイヤモンド I"
        case 166...185: return "ダイヤモンド II"
        case 186...200: return "ダイヤモンド III"
        case 201...250: return "マスター I"
        case 251...300: return "マスター II"
        default: return "マスター III"
        }
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
        default:
            return 12
        }
    }
    
    // 次のレベルまでの必要経験値を計算
    func getExperienceForNextLevel(level: Int) -> Double {
        return Double(level * 100 + Int(pow(Double(level), 1.5) * 50))
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
                Text(getTrophyName(level: user.level))
                    .font(.system(size: 11))
                    .foregroundColor(trophyInfo.color.opacity(0.9))
                
                Text(user.nickname)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 右側：経験値情報（コンパクト版）
            VStack(alignment: .trailing, spacing: 4) {
                // 経験値プログレスバー（細く）
                ProgressView(value: user.experience, total: getExperienceForNextLevel(level: user.level))
                    .tint(.yellow)
                    .frame(width: 100, height: 3)
                    .background(
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(.white.opacity(0.1))
                    )
                
                // 経験値テキスト
                Text("\(Int(user.experience))/\(Int(getExperienceForNextLevel(level: user.level)))")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
                
                // 次のレベルまで
                Text("次Lvまで\(Int(getExperienceForNextLevel(level: user.level) - user.experience))")
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
}

// レベルバッジコンポーネント
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
        default:
            return 10
        }
    }
    
    // レベルに応じた背景色（グラデーション）
    var badgeGradient: LinearGradient {
        switch level {
        case 1...20:  // ブロンズ帯
            return LinearGradient(
                colors: [Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.6, green: 0.4, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 21...50:  // シルバー帯
            return LinearGradient(
                colors: [Color.white.opacity(0.9), Color.gray],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 51...100:  // ゴールド帯
            return LinearGradient(
                colors: [Color.yellow, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:  // レベル100以上（レジェンド）
            return LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
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
                Text("\(level)")
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text("Lv")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
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
            
            // レベル35のシルバーユーザー
            UserStatusCard(user: User(
                id: "2",
                nickname: "中級者花子",
                level: 35,
                experience: 1500,
                totalStudyTime: 36000
            ))
            .environmentObject(MainViewModel.mock)
            
            // レベル75のゴールドユーザー
            UserStatusCard(user: User(
                id: "3",
                nickname: "上級者次郎",
                level: 75,
                experience: 3000,
                totalStudyTime: 360000
            ))
            .environmentObject(MainViewModel.mock)
            
            // レベル100のゴールドユーザー（3桁テスト）
            UserStatusCard(user: User(
                id: "4",
                nickname: "マスター",
                level: 100,
                experience: 4500,
                totalStudyTime: 500000
            ))
            .environmentObject(MainViewModel.mock)
            
            // レベル999のレジェンド（3桁最大テスト）
            UserStatusCard(user: User(
                id: "5",
                nickname: "レジェンド",
                level: 999,
                experience: 9999,
                totalStudyTime: 9999999
            ))
            .environmentObject(MainViewModel.mock)
        }
        .padding()
    }
}
#endif
