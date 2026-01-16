//
//  DepartmentService.swift
//  StudyArena
//
//  Created by 田中正造 on 2026/01/08.
//
//部門データに関する取得&保存。部門データに関するDBとのやりとりは全てこちらに保存。
//戻り値は全部データにする

import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseAuth

class DepartmentService{
    private var db = Firestore.firestore()
    //DBから部門のドキュメントを取ってくる。
    func fetchDepartments() async throws -> [Department] {
        let snapshot = try await db.collection("departments").getDocuments()
        
        // ドキュメントをDepartment型に変換して配列で返す
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Department.self)
        }
    }
    
    
    // 部門メンバー一覧を取得
    func fetchDepartmentMembers(departmentId: String) async throws -> [DepartmentMember] {
        // 1. メンバーシップ情報を取得
        let membershipsSnapshot = try await db.collection("department_memberships")
            .whereField("departmentId", isEqualTo: departmentId)
            .getDocuments()
        
        var members: [DepartmentMember] = []
        
        // 2. 各メンバーシップからユーザー情報を取得
        for doc in membershipsSnapshot.documents {
            guard let membership = try? doc.data(as: DepartmentMembership.self) else { continue }
            
            let userDoc = try await db.collection("users").document(membership.userId).getDocument()
            
            if let userData = try? userDoc.data(as: User.self) {
                let member = DepartmentMember(
                    id: membership.userId,
                    nickname: userData.nickname,
                    level: userData.level,
                    role: membership.role,
                    joinedAt: membership.joinedAt,
                    totalStudyTime: userData.totalStudyTime
                )
                members.append(member)
            }
        }
        // ソートして返す
        return members.sorted { $0.role.sortOrder < $1.role.sortOrder }
    }
    
    // 部門から脱退
    func leaveDepartment(departmentId: String, membershipId: String) async throws {
        // メンバーシップ削除
        try await db.collection("department_memberships").document(membershipId).delete()
        
        // メンバー数減少
        try await db.collection("departments").document(departmentId).updateData([
            "memberCount": FieldValue.increment(Int64(-1))
        ])
    }
    
    // メンバーの役割変更
    func updateMemberRole(membershipId: String, newRole: MemberRole) async throws {
        try await db.collection("department_memberships").document(membershipId).updateData([
            "role": newRole.rawValue
        ])
    }
    
    // メンバー追放
    func kickMember(departmentId: String, membershipId: String) async throws {
        try await leaveDepartment(departmentId: departmentId, membershipId: membershipId)
    }

    // リーダー権限委譲
    func transferLeadership(departmentId: String, currentLeaderMembershipId: String, newLeaderMembershipId: String) async throws {
        let batch = db.batch()
        
        // 現リーダーをサブリーダーに降格
        let currentLeaderRef = db.collection("department_memberships").document(currentLeaderMembershipId)
        batch.updateData(["role": MemberRole.subLeader.rawValue], forDocument: currentLeaderRef)
        
        // 新リーダーをリーダーに昇格
        let newLeaderRef = db.collection("department_memberships").document(newLeaderMembershipId)
        batch.updateData(["role": MemberRole.leader.rawValue], forDocument: newLeaderRef)
        
        try await batch.commit()
    }
    
    // 参加している部門を取得（UserDepartments用）
    func fetchUserMemberships(userId: String) async throws -> [DepartmentMembership] {
        let snapshot = try await db.collection("department_memberships") // または department_memberships
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: DepartmentMembership.self) }
    }
    // MARK: - 更新系 (Action)
    
    // 部門に参加する
    // userId と departmentName は「引数」でもらう！
    func joinDepartment(departmentId: String, departmentName: String, userId: String) async throws {
        
        let membership = DepartmentMembership(
            userId: userId,
            departmentId: departmentId,
            departmentName: departmentName,
            role: .member, // デフォルトはメンバー
        )
        
        // Firestoreに保存
        // 1. ユーザーのサブコレクションに追加（※あなたの設計に合わせてパスは要調整）
        try await db.collection("department_memberships")
            .document(membership.id) // IDは "userId_deptId" 等にするのが推奨
            .setData(from: membership)
        
        // 2. 部門のメンバー数をカウントアップ
        try await db.collection("departments").document(departmentId)
            .updateData(["memberCount": FieldValue.increment(Int64(1))])
        
    }
    
    // 部門を作成する
    func createDepartment(name: String, description: String, creatorId: String, creatorName: String) async throws {
        
        let newDepartment = Department(
            name: name,
            description: description,
            creatorName: creatorName,
            creatorId: creatorId
        )
        
        // 部門ドキュメント作成
        let ref = try await db.collection("departments").addDocument(from: newDepartment)
        
        // 作成と同時に参加処理も行う（自分自身のメソッドを呼ぶ）
        let membership = DepartmentMembership(
            userId: creatorId,
            departmentId: ref.documentID,
            departmentName: name,
            role: .leader
        )
        try await db.collection("department_memberships")
            .document(membership.id)
            .setData(from: membership)
        
    }
    
}
