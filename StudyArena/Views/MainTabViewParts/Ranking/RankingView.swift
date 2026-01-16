//
//  RankingView.swift - シンプル版（ソート機能なし）
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

struct RankingView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var rankingViewModel = RankingViewModel()
    
    // 🔧 削除: フィルター関連の状態変数をコメントアウト
    // @State private var selectedFilter: RankingFilter = .all
    // @State private var selectedDepartment: Department? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 🔧 削除: フィルター選択セクションをコメントアウト
            /*
             // フィルター選択
             ScrollView(.horizontal, showsIndicators: false) {
             HStack(spacing: 10) {
             ForEach(RankingFilter.allCases, id: \.self) { filter in
             FilterChip(
             filter: filter,
             isSelected: selectedFilter == filter,
             action: {
             selectedFilter = filter
             loadFilteredRanking()
             }
             )
             }
             }
             .padding()
             }
             
             // 部門選択（部門フィルターの場合）
             if selectedFilter == .department {
             DepartmentSelector(
             departments: viewModel.departments,
             selectedDepartment: $selectedDepartment
             )
             }
             */
            
            // ランキングリスト（シンプル版）
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.ranking) { user in
                        RankingRow(user: user)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 10)
            }
            .refreshable {
                viewModel.loadRanking()
            }
        }
        .onAppear {
            // 🔧 シンプル化: デフォルトで全体ランキングのみ読み込み
            Task {
                await rankingViewModel.loadRanking()
            }
        }
    }
    
    // 🔧 削除: フィルター関連のメソッドをコメントアウト
    /*
     private func loadFilteredRanking() {
     switch selectedFilter {
     case .all:
     viewModel.loadRanking()
     case .department:
     if let deptId = selectedDepartment?.id {
     Task {
     // 部門ランキング読み込み
     }
     }
     case .monthly:
     // 今月のランキング
     break
     default:
     break
     }
     }
     */
}

// ダイヤモンドまでのランキング行（変更なし）
struct RankingRow: View {
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
        case 101...175:
            return (Color.cyan, "star.circle.fill")
        default: // 176以上はダイヤモンド
            return (Color.purple, "rhombus.fill")
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
                    
                    // ダイヤモンド特別表示
                    if user.level >= 176 {
                        Text("💎")
                            .font(.system(size: 12))
                    }
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

// 🔧 コメントアウト: フィルター関連のコンポーネント
/*
 struct FilterChip: View {
 let filter: RankingFilter
 let isSelected: Bool
 let action: () -> Void
 
 var body: some View {
 Button(action: action) {
 Text(filter.rawValue)
 .padding(.horizontal, 12)
 .padding(.vertical, 6)
 .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
 .foregroundColor(.white)
 .cornerRadius(15)
 }
 }
 }
 
 struct DepartmentSelector: View {
 let departments: [Department]
 @Binding var selectedDepartment: Department?
 
 var body: some View {
 // 部門選択UIの実装
 Text("部門選択")
 }
 }
 */

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    RankingView()
        .environmentObject(MainViewModel.mock)
}
#endif
