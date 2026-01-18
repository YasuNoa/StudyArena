//
//  DepartmentCard.swift
//  StudyArena
//
//  Created by 田中正造 on 2025/01/04.
//
//  部門の概要（名前、人数、説明など）をカード形式で表示するコンポーネント
//  一覧表示や所属リストで共通して使用する
//
import SwiftUI

struct DepartmentCard<ActionButton: View>: View {
    let department: Department
    let role: MemberRole? // 所属している場合、その役職
    let actionButton: ActionButton // 右側に表示するボタンやテキスト
    
    // アクションボタンがない場合のイニシャライザ
    init(department: Department, role: MemberRole? = nil, @ViewBuilder actionButton: () -> ActionButton) {
        self.department = department
        self.role = role
        self.actionButton = actionButton()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // デフォルトアイコン
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(department.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // 役職バッジ（あれば表示）
                        if let role = role {
                            Text(role.displayName)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(roleColor(role).opacity(0.2))
                                .foregroundColor(roleColor(role))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(department.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 注入されたアクションボタン（参加ボタンや矢印など）
                actionButton
            }
            
            // 下部情報（作成者、人数、日付）
            HStack {
                // 作成者
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text("作成者: \(department.creatorName)")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                // 人数
                HStack(spacing: 4) {
                    Image(systemName: "person.3.fill")
                        .font(.caption2)
                    Text("\(department.memberCount)人")
                        .font(.caption2)
                }
                .foregroundColor(.blue.opacity(0.8))
                
                // 作成日
                Text(formatDate(department.createdAt))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.leading, 8)
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
    
    private func roleColor(_ role: MemberRole) -> Color {
        switch role {
        case .leader: return .yellow
        case .subLeader: return .orange
        case .elder: return .cyan
        case .member: return .white
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = Date.jstFormatter
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// プレビュー用
extension DepartmentCard where ActionButton == EmptyView {
    init(department: Department, role: MemberRole? = nil) {
        self.init(department: department, role: role) { EmptyView() }
    }
}
