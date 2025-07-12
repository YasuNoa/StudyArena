//
//  RankingRow.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

// 既存のRankingViewで使用されている場合のために残しておく
struct RankingRow: View {
    let user: User
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        HStack {
            Text("\(user.rank ?? 0)")
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: 40)
                .foregroundColor(rankColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .fontWeight(.semibold)
                Text("Lv. \(user.level)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(viewModel.formatTime(user.totalStudyTime))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var displayName: String {
        let isCurrentUser = user.id == viewModel.user?.id
        
        if isCurrentUser, let currentNickname = viewModel.user?.nickname {
            return currentNickname.isEmpty ? "名無しさん" : currentNickname
        } else {
            if user.nickname.isEmpty || user.nickname == "挑戦者" {
                return "名無しさん"
            }
            return user.nickname
        }
    }
    
    private var rankColor: Color {
        switch user.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .primary
        }
    }
}

#Preview {
    let sampleUser = User(
        id: "1",
        nickname: "田中正造",
        level: 10,
        totalStudyTime: 3600,
        rank: 1
    )
    
    RankingRow(user: sampleUser)
        .environmentObject(MainViewModel.mock)
        .previewLayout(.sizeThatFits)
        .padding()
}
