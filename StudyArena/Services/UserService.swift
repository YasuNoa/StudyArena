// UserService.swift
import Foundation
import Firebase
import FirebaseFirestore

class UserService {
    private let db = Firestore.firestore()
    
    // ユーザー情報の取得
    func fetchUser(uid: String) async throws -> User {
        let document = try await db.collection("users").document(uid).getDocument()
        
        if document.exists {
            var user = try document.data(as: User.self)
            user.id = uid
            return user
        } else {
            // 新規作成
            let newUser = User(id: uid, nickname: "挑戦者")
            try await saveUser(newUser)
            return newUser
        }
    }
    
    // ユーザー情報の保存
    func saveUser(_ user: User) async throws {
        guard let uid = user.id else { return }
        try await db.collection("users").document(uid).setData(from: user, merge: true)
    }
    
    // ランキング取得
    func loadRanking(limit: Int = 100) async -> [User] {
        do {
            let snapshot = try await db.collection("users")
                .order(by: "totalStudyTime", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            var rank = 1
            return snapshot.documents.compactMap { doc in
                var user = try? doc.data(as: User.self)
                user?.id = doc.documentID
                user?.rank = rank
                rank += 1
                return user
            }
        } catch {
            print("ランキング取得エラー: \(error)")
            return []
        }
    }
    
    // 経験値更新（計算ロジック）
    func updateExperience(userId: String, amount: TimeInterval) async {
        do {
            var user = try await fetchUser(uid: userId)
            
            user.experience += amount
            user.totalStudyTime += amount
            
            // レベルアップ計算
            while user.experience >= user.experienceForNextLevel {
                user.experience -= user.experienceForNextLevel
                user.level += 1
            }
            
            try await saveUser(user)
        } catch {
            print("経験値更新エラー: \(error)")
        }
    }
    
    // ニックネーム更新
    func updateNickname(userId: String, name: String) async throws {
        try await db.collection("users").document(userId).updateData(["nickname": name])
    }
    
    // MBTI更新
    func updateMBTI(userId: String, mbti: String?) async throws {
        let data: [String: Any] = ["mbtiType": mbti as Any]
        try await db.collection("users").document(userId).updateData(data)
    }
}
