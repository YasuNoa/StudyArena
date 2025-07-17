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
            // ミニマルダーク背景
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

// ミニマルダーク背景
struct MinimalDarkBackgroundView: View {
    var body: some View {
        ZStack {
            // ベースグラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 微細なテクスチャ効果
            GeometryReader { geometry in
                // 斜めのグラデーションライン
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.01),
                                    .clear,
                                    .white.opacity(0.005)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geometry.size.width * 2)
                        .rotationEffect(.degrees(45))
                        .offset(x: CGFloat(index) * 100 - 200)
                        .opacity(0.5)
                }
            }
            .ignoresSafeArea()
            
            // 上部のハイライト
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        .white.opacity(0.03),
                        .clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}

// ミニマルランキング行
struct MinimalRankingRow: View {
    let user: User
    @EnvironmentObject var viewModel: MainViewModel
    
    var isCurrentUser: Bool {
        user.id == viewModel.user?.id
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // ランク表示（ミニマル）
            Text("\(user.rank ?? 0)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(rankColor)
                .frame(width: 40, alignment: .center)
            
            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                Text(user.nickname)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCurrentUser ? .white : .white.opacity(0.9))
                
                HStack(spacing: 12) {
                    Text("Lv.\(user.level)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(viewModel.formatTime(user.totalStudyTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
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
