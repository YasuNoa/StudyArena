//
//  DepartmentViewModel.swift
//  StudyArena
//
//  Created by 田中正造 on 2026/01/08.
//

//mainviewmodelにおいてuser情報が渡されているかを確認すべし

import Foundation
import Combine

@MainActor
class DepartmentViewModel: ObservableObject {
    
    @Published var departments: [Department] = []
    @Published var userDepartments: [DepartmentMembership] = [] // ← 自分の所属リストも保持
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var userId:String?
    var user: User?
    
    private let service = DepartmentService()
    
    func loadDepartments() {
        self.isLoading = true
        Task {
            do {
                let fetchedDepartments = try await service.fetchDepartments()
                
                self.departments = fetchedDepartments
                self.isLoading = false
                
            } catch {
                print("部門の取得エラー: \(error)")
                self.isLoading = false
            }//このselfはインスタンス自体を指す。すなわち、
        }
    }
    
    func loadDepartmentRanking(departmentId: String) async throws -> [DepartmentMember] {
        // 部門メンバーのIDを取得
        
        let members = try await service.fetchDepartmentMembers(departmentId: departmentId)
        
        // DepartmentMember -> User の簡易変換 (必要な情報だけ)
        return members.sorted { $0.totalStudyTime > $1.totalStudyTime }
    }
    
    
    //自分の所属を取得
    func loadUserMemberships() async {
        guard let userId = self.userId else { return }
        
        
        do {
            let memberships = try await service.fetchUserMemberships(userId: userId)
            self.userDepartments = memberships
            print("Userの所属部門情報を取得しました")
        } catch {
            print("ユーザー参加部門取得エラー: \(error)")
        }
    }
    func joinDepartment(_ department: Department) async throws {
        guard let departmentId = department.id else {
            throw NSError(domain: "DepartmentError", code: 2, userInfo: [NSLocalizedDescriptionKey: "部門IDが無効です"])
        }
        guard let userId = self.userId else {
            throw NSError(domain: "DepartmentError", code: 5, userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが見つかりません"])
        }
        do {
            // Serviceにお願い！
            try await service.joinDepartment(
                departmentId: departmentId,
                departmentName: department.name,
                userId: userId
            )
            // リスト更新
            loadDepartments()
            await loadUserMemberships()
            print("参加成功")
        } catch {
            throw error
        }
        
    }
    //特定の部門に参加しているかのチェック。このままでよきかな。
    func isJoinedDepartment(_ departmentId: String) -> Bool {
        return userDepartments.contains { membership in
            membership.departmentId == departmentId
        }
    }
    
    func createDepartment(name: String, description: String) async throws {
        guard let user = self.user,
              let userId = self.userId
        else {
            throw NSError(domain: "DepartmentError", code: 4, userInfo: [NSLocalizedDescriptionKey: "ユーザー情報が見つかりません"])
        }
        if user.level < 10 {
            throw NSError(domain: "DepartmentError", code: 10, userInfo: [NSLocalizedDescriptionKey: "レベル10以上のユーザーのみ部門を作成できます"])
        }
        print("部門作成処理を開始しました")
        
        do {
            try await service.createDepartment(
                name: name,
                description: description,
                creatorId: userId,
                creatorName: user.nickname
            )
            
            loadDepartments()
            await loadUserMemberships()
            print("作成成功")
            
        } catch {
            print("❌ 部門作成エラー: \(error.localizedDescription)")
            
            throw error
        }
    }
    
    
    
}


