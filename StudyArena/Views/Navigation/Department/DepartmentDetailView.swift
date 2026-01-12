//
//  DepartmentDetailView.swift
//  StudyArena
//
//  部門詳細ビュー（クラロワ風）
//

import SwiftUI

struct DepartmentDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    let department: Department
    
    @State private var members: [DepartmentMember] = []
    @State private var isLoading = true
    @State private var showingLeaveAlert = false
    @State private var errorMessage: String?
    
    // 現在のユーザーのメンバーシップ情報
    private var currentUserMembership: DepartmentMembership? {
        viewModel.userDepartments.first { $0.departmentId == department.id }
    }
    
    // 現在のユーザーの役割
    private var currentUserRole: MemberRole? {
        currentUserMembership?.role
    }
    
    // 参加しているか
    private var isJoined: Bool {
        currentUserMembership != nil
    }
    
    // リーダーかどうか
    private var isLeader: Bool {
        currentUserRole == .leader
    }
    
    var body: some View {
        ZStack {
            MinimalDarkBackgroundView()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 部門プロフィールバー
                    departmentProfileCard
                    
                    // 参加/脱退ボタン
                    actionButton
                    
                    // メンバー一覧
                    DepartmentMemberListView(
                        members: members,
                        currentUserRole: currentUserRole,
                        departmentId: department.id ?? "",
                        leaderId: department.creatorId
                    )
                }
                .padding()
            }
        }
        .navigationTitle(department.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMembers()
        }
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .alert("部門から脱退しますか？", isPresented: $showingLeaveAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("脱退", role: .destructive) {
                leaveDepartment()
            }
        } message: {
            if isLeader && department.memberCount > 1 {
                Text("リーダーは他のメンバーがいる間は脱退できません。先にリーダーを譲渡してください。")
            } else {
                Text("本当に脱退しますか？")
            }
        }
    }
    
    // MARK: - 部門プロフィールカード
    private var departmentProfileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー：部門名とアイコン
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(department.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "person.3.fill")
                            .font(.caption)
                        Text("\(department.memberCount)/\(department.maxMembers)")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // 承認制バッジ
                if !department.isOpenToAll {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                        Text("承認制")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.3))
                    )
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // 説明
            Text(department.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            // タグ
            if !department.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(department.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.2))
                                )
                        }
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // 統計情報
            HStack(spacing: 20) {
                StatItem(icon: "person.fill", title: "作成者", value: department.creatorName)
                Spacer()
                StatItem(icon: "calendar", title: "作成日", value: formatDate(department.createdAt))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - アクションボタン
    private var actionButton: some View {
        Group {
            if isJoined {
                // 脱退ボタン
                Button(action: {
                    if isLeader && department.memberCount > 1 {
                        // リーダーで他のメンバーがいる場合は警告
                        errorMessage = "リーダーは他のメンバーがいる間は脱退できません。先にリーダーを譲渡してください。"
                    } else {
                        showingLeaveAlert = true
                    }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("脱退する")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
            } else {
                // 参加ボタン
                Button(action: joinDepartment) {
                    HStack {
                        Image(systemName: department.isOpenToAll ? "person.badge.plus" : "envelope.fill")
                        Text(department.isOpenToAll ? "参加する" : "参加リクエストを送る")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        department.isFull ? Color.gray : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .disabled(department.isFull)
            }
        }
    }
    
    // MARK: - ヘルパー関数
    
    private func loadMembers() async {
        isLoading = true
        
        // TODO: ViewModelにメンバー取得メソッドを追加する必要があります
        // 仮のデータで表示
        await MainActor.run {
            // 実際はFirestoreから取得
            members = []
            isLoading = false
        }
    }
    
    private func joinDepartment() {
        Task {
            do {
                try await viewModel.joinDepartment(department)
                await loadMembers()
            } catch {
                errorMessage = "参加に失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    private func leaveDepartment() {
        Task {
            do {
                guard let departmentId = department.id else { return }
                // TODO: ViewModelに脱退メソッドを追加する必要があります
                // try await viewModel.leaveDepartment(departmentId)
                errorMessage = "脱退機能は実装中です"
            } catch {
                errorMessage = "脱退に失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - 統計アイテム
struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationView {
        DepartmentDetailView(
            department: Department(
                name: "朝活部",
                description: "朝から一緒に勉強しましょう！",
                creatorName: "太郎",
                creatorId: "user123",
                tags: ["朝活", "集中", "継続"],
                isOpenToAll: true
            )
        )
        .environmentObject(MainViewModel())
    }
}
