//
//  RankingView.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

struct RankingView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.ranking.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("ランキングデータがありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("下にスワイプして更新してください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.ranking) { user in
                        RankingRow(user: user)
                    }
                }
            }
            .navigationTitle("全国ランキング")
            .onAppear {
                viewModel.loadRanking()
            }
            .refreshable {
                viewModel.loadRanking()
            }
        }
    }
}
