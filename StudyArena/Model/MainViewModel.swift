// FileName: MainViewModel.swift

import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MainViewModel: ObservableObject {
    
    @Published var user: User?
    @Published var ranking: [User] = []
    
    @Published var timerValue: TimeInterval = 0
    @Published var isTimerRunning: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var userId: String?
    private var timer: Timer?
    
    // MainViewModel.swift の init() メソッドをデバッグ版に変更
    
    init() {
        // デバッグ: 環境変数を確認
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        print("🔍 環境チェック:")
        print("   - isPreview: \(isPreview)")
        print("   - 実行環境: \(isPreview ? "プレビュー" : "シミュレーター/実機")")
        
        if !isPreview {
            print("🚀 Firebase認証を開始します...")
            authenticateUser()
        } else {
            print("📱 プレビューモード: モックデータを使用")
            self.isLoading = false
            self.userId = "previewUserID"
            self.user = User(
                id: "previewUserID",
                nickname: "プレビューユーザー",
                level: 5,
                experience: 250,
                totalStudyTime: 3600
            )
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    
    // MARK: - Authentication & Data Loading
    func retryAuthentication() {
        isLoading = true
        errorMessage = nil
        authenticateUser()
    }
    private func authenticateUser() {
        print("🔐 authenticateUser() が呼ばれました")
        print("🔥 Firebase Auth の状態を確認中...")
        
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            print("🔐 signInAnonymously のコールバックが呼ばれました")
            
            Task { @MainActor in
                guard let self = self else {
                    print("❌ self が nil です")
                    return
                }
                
                if let error = error {
                    print("❌ 認証エラー: \(error.localizedDescription)")
                    print("   エラー詳細: \(error)")
                    self.handleError("認証に失敗しました", error: error)
                    return
                }
                
                guard let authUser = authResult?.user else {
                    print("❌ authResult.user が nil です")
                    self.handleError("認証に失敗しました", error: nil)
                    return
                }
                
                print("✅ 認証成功! UID: \(authUser.uid)")
                self.userId = authUser.uid
                await self.loadUserData(uid: authUser.uid)
            }
        }
    }
    
    private func loadUserData(uid: String) async {
        print("📊 loadUserData() 開始 - UID: \(uid)")
        
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            print("📄 Firestoreドキュメント取得完了")
            
            if document.exists {
                print("✅ 既存ユーザーデータが見つかりました")
                var loadedUser = try document.data(as: User.self)
                loadedUser.id = uid
                
                if loadedUser.nickname.isEmpty {
                    loadedUser.nickname = "挑戦者"
                    try await self.saveUserData(userToSave: loadedUser)
                }
                
                self.user = loadedUser
                print("👤 ユーザーデータ設定完了: \(loadedUser.nickname)")
                
            } else {
                print("🆕 新規ユーザーを作成します")
                var newUser = User(id: uid, nickname: "挑戦者")
                self.user = newUser
                try await self.saveUserData(userToSave: newUser)
            }
            
            print("✅ isLoading を false に設定します")
            self.isLoading = false
            
        } catch {
            print("❌ loadUserData エラー: \(error)")
            self.handleError("ユーザーデータのロードに失敗しました", error: error)
        }
    }
    // MARK: - Data Persistence
    func saveUserData(userToSave: User) async throws {
        guard let uid = self.userId else {
            throw NSError(domain: "UserDataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが見つかりません"])
        }
        
        // プレビュー環境をチェック
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreview {
            // プレビュー時は実際の保存をスキップし、ローカルデータのみ更新
            print("📱 プレビューモード: データ保存をスキップ")
            self.user = userToSave
            return
        }
        
        do {
            try await db.collection("users").document(uid).setData(from: userToSave, merge: true)
        } catch {
            throw error
        }
    }
    
    // MARK: - Ranking
    func loadRanking() {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreview {
            // プレビュー時はモックデータを使用
            self.ranking = [
                User(id: "rank1", nickname: "レベルアップ王", level: 50, totalStudyTime: 1000000, rank: 1),
                User(id: "rank2", nickname: "勉強の達人", level: 48, totalStudyTime: 980000, rank: 2),
                User(id: "rank3", nickname: "努力家さん", level: 45, totalStudyTime: 850000, rank: 3),
                User(id: "previewUserID", nickname: "プレビューユーザー", level: 5, totalStudyTime: 3600, rank: 15),
            ]
            return
        }
        
        // 通常のFirestore処理
        Task { @MainActor in
            do {
                let querySnapshot = try await db.collection("users")
                    .order(by: "totalStudyTime", descending: true)
                    .limit(to: 100)
                    .getDocuments()
                
                var rank = 1
                self.ranking = querySnapshot.documents.compactMap { doc -> User? in
                    do {
                        var user = try doc.data(as: User.self)
                        user.rank = rank
                        user.id = doc.documentID
                        rank += 1
                        return user
                    } catch {
                        return nil
                    }
                }
            } catch {
                self.handleError("ランキングの取得に失敗しました", error: error)
            }
        }
    }
    
    // MARK: - Timer & Experience Logic
    func startTimer() {
        guard !isTimerRunning else { return }
        
        isTimerRunning = true
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerValue += 1
            }
        }
    }
    
    func stopTimer() {
        guard isTimerRunning else { return }
        
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        
        let studyTime = timerValue
        timerValue = 0
        
        Task { @MainActor in
            self.addExperience(from: studyTime)
            
            guard let userToSave = self.user else { return }
            do {
                try await self.saveUserData(userToSave: userToSave)
            } catch {
                self.handleError("データの保存に失敗しました", error: error)
            }
        }
    }
    
    private func addExperience(from studyTime: TimeInterval) {
        guard var user = self.user else { return }
        
        let earnedExp = studyTime
        user.experience += earnedExp
        user.totalStudyTime += studyTime
        
        var leveledUp = false
        while user.experience >= user.experienceForNextLevel {
            user.experience -= user.experienceForNextLevel
            user.level += 1
            leveledUp = true
        }
        
        self.user = user
        
        if leveledUp {
            // レベルアップ時の通知などをここに追加できる
        }
    }
    
    private func handleError(_ message: String, error: Error?) {
        self.errorMessage = error?.localizedDescription ?? message
        self.isLoading = false
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let totalHours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        
        if totalHours > 0 {
            return String(format: "%d:%02d:%02d", totalHours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // ★★★ ここから下がプレビュー用のコード ★★★
    // MainViewModel.swift の mock プロパティを以下のように更新
    
    // MainViewModel.swift の mock プロパティを修正
    
#if DEBUG
    static let mock: MainViewModel = {
        let viewModel = MainViewModel()
        
        // ⚠️ 重要: userIdを設定
        viewModel.userId = "mockUserID"
        
        // 基本データを設定
        viewModel.user = User(
            id: "mockUserID",
            nickname: "プレビュー太郎",
            level: 10,
            experience: 1200,
            totalStudyTime: 54000,
            rank: 15
        )
        
        // ランキングデータを生成
        viewModel.ranking = [
            User(id: "rank1", nickname: "レベルアップ王", level: 50, experience: 0, totalStudyTime: 1000000, rank: 1),
            User(id: "rank2", nickname: "勉強の達人", level: 48, experience: 0, totalStudyTime: 980000, rank: 2),
            User(id: "rank3", nickname: "努力家さん", level: 45, experience: 0, totalStudyTime: 850000, rank: 3),
            User(id: "rank4", nickname: "コツコツ君", level: 42, experience: 0, totalStudyTime: 720000, rank: 4),
            User(id: "rank5", nickname: "頑張り屋", level: 40, experience: 0, totalStudyTime: 650000, rank: 5),
            User(id: "mockUserID", nickname: "プレビュー太郎", level: 10, experience: 1200, totalStudyTime: 54000, rank: 15),
        ]
        
        // 状態を設定
        viewModel.isLoading = false
        viewModel.errorMessage = nil
        viewModel.timerValue = 0
        viewModel.isTimerRunning = false
        
        return viewModel
    }()
#endif
}
