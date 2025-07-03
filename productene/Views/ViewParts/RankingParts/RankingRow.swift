//
//  RankingRow.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

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
                Text(user.nickname)
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
    
    private var rankColor: Color {
        switch user.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .primary
        }
    }
}
