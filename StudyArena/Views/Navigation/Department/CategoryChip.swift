//
//  CategoryChip.swift
//  StudyArena
//
//  Created by 田中正造 on 2025/01/04.
//
//  カテゴリやタグを表示するためのチップコンポーネント
//

import SwiftUI

// 🔧 修正: DepartmentCategoryを使わず、シンプルなString型のカテゴリチップ
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? Color.blue : Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}
