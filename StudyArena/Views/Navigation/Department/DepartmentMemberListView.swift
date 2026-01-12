//
//  DepartmentMemberListView.swift
//  StudyArena
//
//  部門メンバー一覧ビュー
//

import SwiftUI

struct DepartmentMemberListView: View {
    let members: [DepartmentMember]
    let currentUserRole: MemberRole?
    let departmentId: String
    let leaderId: String
    
    @State private var selectedMember: DepartmentMember?
    @State private var showingMemberActions = false
    @EnvironmentObject var viewModel: MainViewModel
    
    // 役割ごとにメンバーをグループ化
    private var groupedMembers: [(role: MemberRole, members: [DepartmentMember])] {
        let roles: [MemberRole] = [.leader, .subLeader, .elder, .member]
        return roles.compactMap { role in
            let roleMembers = members.filter { $0.role == role }
            return roleMembers.isEmpty ? nil : (role, roleMembers)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Text("メンバー")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(members.count)人")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal)
            
            // メンバーリスト
            if members.isEmpty {
                emptyView
            } else {
                ForEach(groupedMembers, id: \.role) { group in
                    memberSection(role: group.role, members: group.members)
                }
            }
        }
        .sheet(item: $selectedMember) { member in
            MemberActionSheet(
                member: member,
                currentUserRole: currentUserRole,
                isLeader: currentUserRole == .leader,
                onPromote: { promoteMember(member) },
                onDemote: { demoteMember(member) },
                onKick: { kickMember(member) },
                onTransferLeadership: { transferLeadership(to: member) }
            )
        }
    }
    
    // MARK: - メンバーセクション
    private func memberSection(role: MemberRole, members: [DepartmentMember]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 役割ヘッダー
            HStack(spacing: 6) {
                Text(role.icon)
                    .font(.caption)
                Text(role.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
                Text("(\(members.count))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal)
            
            // メンバーカード
            ForEach(members) { member in
                MemberCard(member: member)
                    .onTapGesture {
                        // リーダーまたはサブリーダーがタップできる
                        if currentUserRole == .leader || currentUserRole == .subLeader {
                            selectedMember = member
                            showingMemberActions = true
                        }
                    }
            }
        }
    }
    
    // MARK: - 空ビュー
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            
            Text("メンバーがいません")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    

    // MARK: - アクション
    
    private func promoteMember(_ member: DepartmentMember) {
        Task {
            do {
                let newRole: MemberRole
                switch member.role {
                case .member:
                    newRole = .elder
                case .elder:
                    newRole = .subLeader
                case .subLeader:
                    newRole = .subLeader // 既に最高位
                case .leader:
                    return // リーダーは昇格不可
                }
                
                try await viewModel.changeMemberRole(
                    userId: member.id,
                    departmentId: departmentId,
                    newRole: newRole
                )
                print("✅ 昇格完了: \(member.nickname) -> \(newRole.displayName)")
            } catch {
                print("❌ 昇格エラー: \(error.localizedDescription)")
            }
        }
    }
    
    private func demoteMember(_ member: DepartmentMember) {
        Task {
            do {
                let newRole: MemberRole
                switch member.role {
                case .subLeader:
                    newRole = .elder
                case .elder:
                    newRole = .member
                case .member:
                    return // 既に最低位
                case .leader:
                    return // リーダーは降格不可
                }
                
                try await viewModel.changeMemberRole(
                    userId: member.id,
                    departmentId: departmentId,
                    newRole: newRole
                )
                print("✅ 降格完了: \(member.nickname) -> \(newRole.displayName)")
            } catch {
                print("❌ 降格エラー: \(error.localizedDescription)")
            }
        }
    }
    
    private func kickMember(_ member: DepartmentMember) {
        Task {
            do {
                try await viewModel.kickMember(
                    userId: member.id,
                    departmentId: departmentId
                )
                print("✅ 追放完了: \(member.nickname)")
            } catch {
                print("❌ 追放エラー: \(error.localizedDescription)")
            }
        }
    }
    
    private func transferLeadership(to member: DepartmentMember) {
        Task {
            do {
                try await viewModel.transferLeadership(
                    departmentId: departmentId,
                    newLeaderId: member.id
                )
                print("✅ リーダー譲渡完了: \(member.nickname)")
            } catch {
                print("❌ リーダー譲渡エラー: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - メンバーカード
struct MemberCard: View {
    let member: DepartmentMember
    
    var body: some View {
        HStack(spacing: 12) {
            // アバター
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(member.nickname.prefix(1))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // メンバー情報
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.role.icon)
                        .font(.caption)
                    Text(member.nickname)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("Lv.\(member.level)")
                            .font(.caption)
                    }
                    .foregroundColor(.yellow)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(formatStudyTime(member.totalStudyTime))
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // 参加日
            VStack(alignment: .trailing, spacing: 2) {
                Text("参加日")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                Text(member.formattedJoinDate)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
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
        .padding(.horizontal)
    }
    
    private func formatStudyTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        if hours > 0 {
            return "\(hours)時間"
        } else {
            let minutes = Int(time) / 60
            return "\(minutes)分"
        }
    }
}

// MARK: - メンバーアクションシート
struct MemberActionSheet: View {
    let member: DepartmentMember
    let currentUserRole: MemberRole?
    let isLeader: Bool
    let onPromote: () -> Void
    let onDemote: () -> Void
    let onKick: () -> Void
    let onTransferLeadership: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    // サブリーダーかどうか
    private var isSubLeader: Bool {
        currentUserRole == .subLeader
    }
    
    // 管理権限があるか（リーダーまたはサブリーダー）
    private var hasManagementPermission: Bool {
        isLeader || isSubLeader
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // メンバー情報
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Text(member.nickname.prefix(1))
                                .font(.system(size: 36))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text(member.nickname)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 6) {
                            Text(member.role.icon)
                            Text(member.role.displayName)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    
                    // アクションボタン
                    if hasManagementPermission && member.role != .leader {
                        VStack(spacing: 12) {
                            // リーダー専用の機能
                            if isLeader {
                                // 昇格
                                if member.role != .subLeader {
                                    ActionButton(
                                        title: "昇格させる",
                                        icon: "arrow.up.circle.fill",
                                        color: .green
                                    ) {
                                        onPromote()
                                        dismiss()
                                    }
                                }
                                
                                // 降格
                                if member.role != .member {
                                    ActionButton(
                                        title: "降格させる",
                                        icon: "arrow.down.circle.fill",
                                        color: .orange
                                    ) {
                                        onDemote()
                                        dismiss()
                                    }
                                }
                                
                                // リーダー譲渡
                                ActionButton(
                                    title: "リーダーを譲渡",
                                    icon: "crown.fill",
                                    color: .yellow
                                ) {
                                    onTransferLeadership()
                                    dismiss()
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                            }
                            
                            // 追放（リーダーとサブリーダー共通）
                            // サブリーダーはエルダーとメンバーのみ追放可能
                            if isLeader || (isSubLeader && member.role != .subLeader) {
                                ActionButton(
                                    title: "部門から追放",
                                    icon: "xmark.circle.fill",
                                    color: .red
                                ) {
                                    onKick()
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("メンバー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - アクションボタン
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(color.opacity(0.3))
            )
        }
    }
}

#Preview {
    DepartmentMemberListView(
        members: [
            DepartmentMember(
                id: "1",
                nickname: "太郎",
                level: 50,
                role: .leader,
                joinedAt: Date(),
                totalStudyTime: 36000
            ),
            DepartmentMember(
                id: "2",
                nickname: "花子",
                level: 35,
                role: .elder,
                joinedAt: Date().addingTimeInterval(-86400 * 7),
                totalStudyTime: 18000
            ),
            DepartmentMember(
                id: "3",
                nickname: "次郎",
                level: 20,
                role: .member,
                joinedAt: Date().addingTimeInterval(-86400 * 3),
                totalStudyTime: 7200
            )
        ],
        currentUserRole: .leader,
        departmentId: "dept123",
        leaderId: "1"
    )
}
