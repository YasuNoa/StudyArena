import Foundation
import Firebase
import FirebaseFirestore

class TimelineService {
    private let db = Firestore.firestore()
    
    // MARK: - 取得系
    
    // タイムライン取得
    func fetchPosts(limit: Int = 30) async throws -> [TimelinePost] {
        let snapshot = try await db.collection("timelinePosts")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        // Codableの力で自動変換（idも自動で入ります）
        return snapshot.documents.compactMap { try? $0.data(as: TimelinePost.self) }
    }
    
    // 今日の投稿数（制限チェック用）
    func fetchTodayPostCount(userId: String) async -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let snapshot = try await db.collection("timelinePosts")
                .whereField("userId", isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("timestamp", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            return snapshot.count
        } catch {
            return 0
        }
    }
    
    // 今日の学習時間（投稿付与用）
    func fetchTodayStudyTime(userId: String) async -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let snapshot = try await db.collection("studyRecords")
                .whereField("userId", isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("timestamp", isLessThan: Timestamp(date: tomorrow))
                .whereField("recordType", isEqualTo: "study")
                .getDocuments()
            
            return snapshot.documents.reduce(0.0) { total, doc in
                return total + (doc.data()["duration"] as? TimeInterval ?? 0)
            }
        } catch {
            return 0
        }
    }
    
    // MARK: - 更新系
    
    // 新規投稿を作成
    func createPost(_ post: TimelinePost) async throws -> TimelinePost {
        // ⭐️ モデルをそのまま渡すだけで保存完了！（辞書変換不要）
        let ref = try await db.collection("timelinePosts").addDocument(from: post)
        
        // 生成されたIDをセットして返す
        var newPost = post
        newPost.id = ref.documentID
        return newPost
    }
    
    // いいね切り替え（トランザクション）
    func toggleLike(postId: String, userId: String) async throws -> (isLiked: Bool, newCount: Int) {
        let postRef = db.collection("timelinePosts").document(postId)
        
        return try await db.runTransaction { (transaction, errorPointer) -> [String: Any]? in
            let postDoc: DocumentSnapshot
            do {
                postDoc = try transaction.getDocument(postRef)
            } catch let nsError as NSError {
                errorPointer?.pointee = nsError
                return nil
            }
            
            guard var postData = postDoc.data() else { return nil }
            
            var likedUserIds = postData["likedUserIds"] as? [String] ?? []
            var likeCount = postData["likeCount"] as? Int ?? 0
            
            let isCurrentlyLiked = likedUserIds.contains(userId)
            let newIsLiked: Bool
            
            if isCurrentlyLiked {
                likedUserIds.removeAll { $0 == userId }
                likeCount = max(0, likeCount - 1)
                newIsLiked = false
            } else {
                likedUserIds.append(userId)
                likeCount += 1
                newIsLiked = true
            }
            
            transaction.updateData([
                "likedUserIds": likedUserIds,
                "likeCount": likeCount
            ], forDocument: postRef)
            
            return ["isLiked": newIsLiked, "newCount": likeCount]
        }
        .map { result -> (Bool, Int) in
            // ここで [String: Any] にキャストする！
            guard let dict = result as? [String: Any] else {
                return (false, 0)
            }
            return (
                dict["isLiked"] as? Bool ?? false,
                dict["newCount"] as? Int ?? 0
            )
        } ?? (false, 0)
    }
    
    // ニックネーム一括更新
    func updateNicknameInAllPosts(userId: String, newNickname: String) async throws {
        let snapshot = try await db.collection("timelinePosts")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["nickname": newNickname], forDocument: doc.reference)
        }
        try await batch.commit()
    }
}
