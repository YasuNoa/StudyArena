//
//  TimeLineViewModel.swift
//  StudyArena
//
//  Created by 田中正造 on 2026/01/09.
//

import Foundation
import Combine

@MainActor
class TimelineViewModel: ObservableObject {
    
    @Published var timelinePosts: [TimelinePost] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // 親から受け取る情報
    var userId: String?
    var user: User?
    
    private let service = TimelineService()
    
    // MARK: - 読み込み
    
    func loadTimelinePosts() {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview {
            self.timelinePosts = createMockTimelinePosts() // 下記のモックメソッドを使用
            return
        }
        
        self.isLoading = true
        Task {
            do {
                let posts = try await service.fetchPosts()
                self.timelinePosts = posts
                self.isLoading = false
            } catch {
                print("タイムライン読み込みエラー: \(error)")
                self.isLoading = false
            }
        }
    }
    
    // MARK: - 投稿アクション
    
    // 投稿作成
    func createTimelinePost(content: String) async throws {
        guard let userId = self.userId, let user = self.user else { return }
        
        // 今日の学習時間を取得
        let todayStudyTime = await service.fetchTodayStudyTime(userId: userId)
        
        // ⭐️ モデルの初期化 (デフォルト値があるものは省略可能ですが、明示的に書いています)
        let post = TimelinePost(
            userId: userId,
            nickname: user.nickname,
            content: content,
            timestamp: Date(),
            level: user.level,
            likeCount: 0,
            likedUserIds: [],
            studyDuration: todayStudyTime > 0 ? todayStudyTime : nil
        )
        
        // 保存実行
        let savedPost = try await service.createPost(post)
        
        // 画面に即座に反映
        self.timelinePosts.insert(savedPost, at: 0)
    }
    
    // 投稿可能かチェック
    func canPostToday() async -> Bool {
        guard let userId = self.userId else { return false }
        let count = await service.fetchTodayPostCount(userId: userId)
        let limit = user?.dailyPostLimit ?? 1
        return count < limit
    }
    
    // MARK: - いいねアクション
    
    func toggleLike(for postId: String) async {
        guard let userId = self.userId else { return }
        
        // プレビュー対策
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview { return }
        
        do {
            let (isLiked, newCount) = try await service.toggleLike(postId: postId, userId: userId)
            
            // ローカル更新
            updateLocalPostLike(postId: postId, isLiked: isLiked, newCount: newCount)
            
        } catch {
            print("いいねエラー: \(error)")
        }
    }
    
    // ローカル配列の更新
    private func updateLocalPostLike(postId: String, isLiked: Bool, newCount: Int) {
        guard let userId = self.userId,
              let index = timelinePosts.firstIndex(where: { $0.id == postId }) else { return }
        
        var updatedPost = timelinePosts[index]
        updatedPost.likeCount = newCount
        
        if isLiked {
            if updatedPost.likedUserIds?.contains(userId) != true {
                updatedPost.likedUserIds = (updatedPost.likedUserIds ?? []) + [userId]
            }
        } else {
            updatedPost.likedUserIds = updatedPost.likedUserIds?.filter { $0 != userId }
        }
        
        timelinePosts[index] = updatedPost
    }
    
    // ユーザーがその投稿にいいね済みか判定 (モデルのメソッドを活用してもOK)
    func isPostLikedByUser(_ post: TimelinePost) -> Bool {
        guard let userId = self.userId else { return false }
        // モデルに定義されているメソッドを使うとスマートです
        return post.isLikedBy(userId: userId)
    }
    
    // MARK: - モックデータ生成
    private func createMockTimelinePosts() -> [TimelinePost] {
        var posts: [TimelinePost] = []
        let calendar = Calendar.current
        
        let mockContents = ["今日も頑張った！", "レベルアップ！", "数学難しい..."]
        
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            
            let post = TimelinePost(
                id: "mock\(i)", // @DocumentID用
                userId: "mockUser",
                nickname: "テストユーザー",
                content: mockContents[i % mockContents.count],
                timestamp: date,
                level: 10 + i,
                likeCount: i * 2,
                likedUserIds: [],
                studyDuration: 3600
            )
            posts.append(post)
        }
        return posts
    }
}
