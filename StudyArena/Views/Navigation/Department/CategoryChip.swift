//
//  CategoryChip.swift
//  StudyArena
//
//  Created by 田中正造 on 2025/09/06.
//
import SwiftUI

struct CategoryChip: View {
    let category: Department.DepartmentCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
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
