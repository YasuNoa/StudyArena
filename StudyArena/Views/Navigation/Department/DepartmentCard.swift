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
                // デフォルトアイコン（DepartmentCategoryがないため）
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
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
            
            // 作成者情報
            HStack {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                Text("作成者: \(department.creatorName)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // メンバー数と作成日
            HStack {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(department.memberCount)人参加中")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Text(formatDate(department.createdAt))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
