//
//  DepartmentCard.swift
//  StudyArena
//
//  Created by 田中正造 on 2025/09/06.
//
import SwiftUI

struct DepartmentCard: View {
    let department: Department
    @State private var isJoined = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // アイコン
                Image(systemName: department.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: department.color) ?? .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(department.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(department.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 参加ボタン
                Button(action: toggleJoin) {
                    Text(isJoined ? "参加中" : "参加")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isJoined ? Color.green : Color.blue)
                        )
                }
            }
            
            // タグ
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(department.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
            }
            
            // メンバー数
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                Text("\(department.memberCount)人参加中")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func toggleJoin() {
        withAnimation(.spring()) {
            isJoined.toggle()
        }
    }
}
