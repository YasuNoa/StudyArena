//
//  RankingView.swift - ミニマルダーク風バージョン
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

struct RankingView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        ZStack {
            // ミニマルダーク背景（共通コンポーネント使用）
            MinimalDarkBackgroundView()
            
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 10) {
                    Text("全国ランキング")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.1), radius: 5)
                    
                    Text("トップ100")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 50)
                .padding(.bottom, 30)
                
                if viewModel.ranking.isEmpty {
                    // 空の状態
                    VStack(spacing: 20) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.2))
                        
                        Text("ランキングデータがありません")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("下にスワイプして更新してください")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // ランキングリスト
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.ranking) { user in
                                MinimalRankingRow(user: user)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .refreshable {
                        viewModel.loadRanking()
                    }
                }
                
                Spacer()
            }
            .onAppear {
                viewModel.loadRanking()
            }
        }
    }
}

// ミニマルランキング行（トロフィー表示追加版）
struct MinimalRankingRow: View {
    let user: User
    @EnvironmentObject var viewModel: MainViewModel
    
    var isCurrentUser: Bool {
        user.id == viewModel.user?.id
    }
    
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
    
    var body: some View {
        HStack(spacing: 16) {
            // ランク表示
            Text("\(user.rank ?? 0)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(rankColor)
                .frame(width: 40, alignment: .center)
            
            // トロフィーアイコン
            Image(systemName: trophyInfo.icon)
                .font(.system(size: 20))
                .foregroundColor(trophyInfo.color)
                .shadow(color: trophyInfo.color.opacity(0.3), radius: 2)
            
            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.nickname)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isCurrentUser ? .white : .white.opacity(0.9))
                    
                    // レベルバッジ
                    Text("Lv.\(user.level)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(trophyInfo.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(trophyInfo.color.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(trophyInfo.color.opacity(0.4), lineWidth: 0.5)
                                )
                        )
                }
                
                // 学習時間
                Text(viewModel.formatTime(user.totalStudyTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // 自分のインジケーター
            if isCurrentUser {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser
                      ? Color.white.opacity(0.08)
                      : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCurrentUser
                            ? Color.white.opacity(0.2)
                            : Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var rankColor: Color {
        switch user.rank {
        case 1: return Color(red: 1, green: 0.84, blue: 0) // ゴールド
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // シルバー
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // ブロンズ
        default: return .white.opacity(0.7)
        }
    }
}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    RankingView()
        .environmentObject(MainViewModel.mock)
}
#endif
