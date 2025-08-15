//
//  TrophyDisplayCard.swift
//  StudyArena
//
//  Created by 田中正造 on 11/08/2025.
//
import SwiftUI

struct TrophyDisplayCard: View {
    let user: User
    
    var trophyColor: Color {
        // レベルから直接色を判定
        switch user.level {
        case 1...20:
            return Color(red: 0.8, green: 0.5, blue: 0.2) // ブロンズ
        case 21...50:
            return Color(white: 0.7) // シルバー
        case 51...100:
            return Color.yellow // ゴールド
        case 101...150:
            return Color.cyan // プラチナ
        case 151...200:
            return Color.purple // ダイヤモンド
        default:
            return Color.red // マスター
        }
    }
    
    var trophyIcon: String {
        // レベルから直接アイコンを判定
        switch user.level {
        case 1...20:
            return "shield.fill"
        case 21...50:
            return "shield.lefthalf.filled"
        case 51...100:
            return "crown.fill"
        case 101...150:
            return "star.circle.fill"
        case 151...200:
            return "rhombus.fill"
        default:
            return "flame.fill"
        }
    }
    
    var body: some View {
        ProfileCard {
            HStack(spacing: 20) {
                // トロフィーアイコン
                if let trophy = user.currentTrophy {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        trophyColor.opacity(0.3),
                                        trophyColor.opacity(0.1)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: trophy.icon)
                            .font(.system(size: 40))
                            .foregroundColor(trophyColor)
                            .shadow(color: trophyColor.opacity(0.5), radius: 10)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    if let trophy = user.currentTrophy {
                        Text(trophy.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("レベル \(user.level)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
        }
    }
}
