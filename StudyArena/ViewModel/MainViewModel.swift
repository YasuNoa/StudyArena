// FileName: MainViewModel.swift

import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MainViewModel: ObservableObject {
    
    // 既存のプロパティ
    @Published var user: User?
    @Published var ranking: [User] = []
    @Published var timerValue: TimeInterval = 0
    @Published var isTimerRunning: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var departments: [Department] = []
    @Published var userDepartments: [DepartmentMembership] = []
    @Published var selectedDepartmentId: String? = nil
    @Published var backgroundTracker = BackgroundTracker()
    @Published var validationWarning: String?
    
    @Published var studyRecords: [StudyRecord] = []
    @Published var studyStatistics: StudyStatistics?
    
    // 日別の学習データ
    @Published var dailyStudyData: [Date: TimeInterval] = [:]
    
    private var db = Firestore.firestore()
    private var userId: String?
    private var timer: Timer?
    
    init() {
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
    
    // 既存のメソッドはそのまま保持
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
                let newUser = User(id: uid, nickname: "挑戦者")
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
    
    func saveUserData(userToSave: User) async throws {
        guard let uid = self.userId else {
            throw NSError(domain: "UserDataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが見つかりません"])
        }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreview {
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
    
    func loadRanking() {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreview {
            self.ranking = [
                User(id: "rank1", nickname: "レベルアップ王", level: 50, totalStudyTime: 1000000, rank: 1),
                User(id: "rank2", nickname: "勉強の達人", level: 48, totalStudyTime: 980000, rank: 2),
                User(id: "rank3", nickname: "努力家さん", level: 45, totalStudyTime: 850000, rank: 3),
                User(id: "previewUserID", nickname: "プレビューユーザー", level: 5, totalStudyTime: 3600, rank: 15),
            ]
            return
        }
        
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
    
    func saveTodayStudyTime(_ time: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())
        dailyStudyData[today] = (dailyStudyData[today] ?? 0) + time
        // saveDailyRecordの呼び出しを削除
    }
    
    //バックグラウンド追跡付きタイマー
    func startTimerWithValidation() {
        guard !isTimerRunning else { return }
        
        // バックグラウンド追跡リセット
        backgroundTracker.resetSession()
      
        
        isTimerRunning = true
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerValue += 1
            }
        }
    }
    
    func loadDepartments() {
        Task { @MainActor in
            do {
                let querySnapshot = try await db.collection("departments")
                    .getDocuments()
                
                self.departments = querySnapshot.documents.compactMap { doc in
                    try? doc.data(as: Department.self)
                }
            } catch {
                print("部門の取得エラー: \(error)")
            }
        }
    }
    
    func joinDepartment(_ departmentId: String) async throws {
        guard let userId = self.userId else { return }
        
        let membership = DepartmentMembership(
            departmentId: departmentId,
            departmentName: departments.first { $0.id == departmentId }?.name ?? "",
            joinedAt: Date()
        )
        
        // Firestoreに保存
        try await db.collection("users").document(userId)
            .collection("departments").document(departmentId)
            .setData(from: membership)
        
        // 部門のメンバー数を更新
        try await db.collection("departments").document(departmentId)
            .updateData(["memberCount": FieldValue.increment(Int64(1))])
        
        userDepartments.append(membership)
    }
    
    func loadDepartmentRanking(departmentId: String) async throws -> [User] {
        // 部門メンバーのIDを取得
        let membersSnapshot = try await db.collection("departments")
            .document(departmentId)
            .collection("members")
            .getDocuments()
        
        let memberIds = membersSnapshot.documents.map { $0.documentID }
        
        // メンバーの情報を取得してランキング作成
        var users: [User] = []
        for id in memberIds {
            if let doc = try? await db.collection("users").document(id).getDocument(),
               var user = try? doc.data(as: User.self) {
                user.id = id
                users.append(user)
            }
        }
        
        return users.sorted { $0.totalStudyTime > $1.totalStudyTime }
    }
    
    func stopTimerWithValidation() {
        guard isTimerRunning else { return }
        
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
      
        
        let studyTime = timerValue
        
        // バックグラウンド時間チェック
        if backgroundTracker.backgroundTimeExceeded {
            validationWarning = "バックグラウンド時間が長すぎるため、今回の学習は記録されません"
            timerValue = 0
            return
        }
        
        // 通常通り経験値を付与
        timerValue = 0
        Task { @MainActor in
            // ⭐️ レベル記録（変更前）
            let beforeLevel = self.user?.level ?? 1
            
            // 経験値を追加
            self.addExperience(from: studyTime)
            //カレンダーに記録
            saveTodayStudyTime(studyTime)
            // ⭐️ レベル記録（変更後）
            let afterLevel = self.user?.level ?? 1
            let earnedExp = studyTime
            
            // ⭐️ 学習記録を保存（これが抜けていた！）
            do {
                try await self.saveStudyRecord(
                    duration: studyTime,
                    earnedExp: earnedExp,
                    beforeLevel: beforeLevel,
                    afterLevel: afterLevel
                )
            } catch {
                print("学習記録の保存エラー: \(error)")
            }
            
            guard let userToSave = self.user else { return }
            do {
                try await self.saveUserData(userToSave: userToSave)
                validationWarning = nil
            } catch {
                self.handleError("データの保存に失敗しました", error: error)
            }
        }
    }
    
    func getStudyTime(for date: Date) -> TimeInterval {
        let day = Calendar.current.startOfDay(for: date)
        return dailyStudyData[day] ?? 0
    }
    // 既存のタイマーメソッド（互換性のため残す）
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
    
    func loadStudyRecords() {
        guard let userId = self.userId else { return }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreview {
            // プレビュー用のモックデータ
            self.studyRecords = createMockStudyRecords()
            self.calculateStatistics()
            return
        }
        
        Task { @MainActor in
            do {
                let querySnapshot = try await db.collection("studyRecords")
                    .whereField("userId", isEqualTo: userId)
                    .order(by: "timestamp", descending: true)
                    .limit(to: 50)
                    .getDocuments()
                
                self.studyRecords = querySnapshot.documents.compactMap { doc -> StudyRecord? in
                    do {
                        return try doc.data(as: StudyRecord.self)
                    } catch {
                        print("学習記録のパースエラー: \(error)")
                        return nil
                    }
                }
                
                // 統計情報を計算
                self.calculateStatistics()
                
            } catch {
                print("学習記録の取得エラー: \(error)")
            }
        }
    }
    

    private func saveStudyRecord(duration: TimeInterval, earnedExp: Double, beforeLevel: Int, afterLevel: Int) async throws {
        guard let userId = self.userId else { return }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview { return }
        
        let recordType: StudyRecord.RecordType = (beforeLevel < afterLevel) ? .levelUp : .study
        
        let record = StudyRecord(
            userId: userId,
            timestamp: Date(),
            duration: duration,
            earnedExperience: earnedExp,
            recordType: recordType,
            beforeLevel: beforeLevel,
            afterLevel: afterLevel
        )
        
        do {
            // ⭐️ 修正: シンプルな辞書形式でデータを保存
            let data: [String: Any] = [
                "userId": userId,
                "timestamp": Timestamp(date: Date()),
                "duration": duration,
                "earnedExperience": earnedExp,
                "recordType": recordType.rawValue,
                "beforeLevel": beforeLevel,
                "afterLevel": afterLevel
            ]
            
            try await db.collection("studyRecords").addDocument(data: data)
            
            // ローカルの配列にも追加
            self.studyRecords.insert(record, at: 0)
            self.calculateStatistics()
        } catch {
            print("学習記録の保存エラー: \(error)")
            throw error
        }
    }
    // 統計情報の計算
    private func calculateStatistics() {
        guard !studyRecords.isEmpty else {
            studyStatistics = nil
            return
        }
        
        // 日付ごとにグループ化
        let calendar = Calendar.current
        let recordsByDate = Dictionary(grouping: studyRecords) { record in
            calendar.startOfDay(for: record.timestamp)
        }
        
        // 総学習日数
        let totalStudyDays = recordsByDate.count
        
        // 現在の連続日数を計算
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        while true {
            if recordsByDate[checkDate] != nil {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if currentStreak == 0 {
                // 今日学習していない場合は昨日をチェック
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                if recordsByDate[checkDate] != nil {
                    currentStreak = 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        // 平均学習時間
        let totalTime = studyRecords.reduce(0) { $0 + $1.duration }
        let averageTime = totalStudyDays > 0 ? totalTime / Double(totalStudyDays) : 0
        
        studyStatistics = StudyStatistics(
            totalStudyDays: totalStudyDays,
            currentStreak: currentStreak,
            longestStreak: currentStreak, // 簡易版
            averageStudyTime: averageTime,
            totalRecords: studyRecords.count
        )
    }
    
    // モックデータ生成（プレビュー用）
    private func createMockStudyRecords() -> [StudyRecord] {
        var records: [StudyRecord] = []
        let calendar = Calendar.current
        
        // 過去7日間のデータを生成
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            
            // 通常の学習記録
            records.append(StudyRecord(
                id: "mock\(i)",
                userId: "mockUserID",
                timestamp: date,
                duration: TimeInterval.random(in: 600...3600),
                earnedExperience: Double.random(in: 100...500),
                recordType: .study,
                beforeLevel: 10,
                afterLevel: 10
            ))
            
            // レベルアップ記録（3回に1回）
            if i % 3 == 0 && i > 0 {
                records.append(StudyRecord(
                    id: "mockLevelUp\(i)",
                    userId: "mockUserID",
                    timestamp: calendar.date(byAdding: .minute, value: 30, to: date)!,
                    duration: 0,
                    earnedExperience: 0,
                    recordType: .levelUp,
                    beforeLevel: 10 - i/3,
                    afterLevel: 11 - i/3
                ))
            }
        }
        
        return records.sorted { $0.timestamp > $1.timestamp }
    }
    // MainViewModel.swift に追加するコード
    
    // MARK: - 既存のプロパティの下に追加
    @Published var timelinePosts: [TimelinePost] = []
    
    // MARK: - タイムライン投稿関連メソッド
    
    // タイムライン投稿の読み込み
    func loadTimelinePosts() {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreview {
            // プレビュー用のモックデータ
            self.timelinePosts = createMockTimelinePosts()
            return
        }
        
        Task { @MainActor in
            do {
                let querySnapshot = try await db.collection("timelinePosts")
                    .order(by: "timestamp", descending: true)
                    .limit(to: 30)
                    .getDocuments()
                
                self.timelinePosts = querySnapshot.documents.compactMap { doc -> TimelinePost? in
                    do {
                        return try doc.data(as: TimelinePost.self)
                    } catch {
                        print("投稿のパースエラー: \(error)")
                        return nil
                    }
                }
            } catch {
                print("投稿の取得エラー: \(error)")
            }
        }
    }
    
    func createTimelinePost(content: String) async throws {
        guard let userId = self.userId,
              let user = self.user else { return }
        
        // その日の学習時間を計算
        let todayStudyTime = await getTodayStudyTime()
        
        let post = TimelinePost(
            userId: userId,
            nickname: user.nickname,
            content: content,
            timestamp: Date(),
            level: user.level,
            studyDuration: todayStudyTime  // 学習時間を追加
        )
        
        do {
            // Firestoreに保存
            let data: [String: Any] = [
                "userId": userId,
                "nickname": user.nickname,
                "content": content,
                "timestamp": Timestamp(date: Date()),
                "level": user.level
            ]
            
            try await db.collection("timelinePosts").addDocument(data: data)
            
            // ローカルの配列にも追加
            self.timelinePosts.insert(post, at: 0)
        } catch {
            print("投稿の作成エラー: \(error)")
            throw error
        }
    }
    
    private func getTodayStudyTime() async -> TimeInterval? {
        guard let userId = self.userId else { return nil }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let querySnapshot = try await db.collection("studyRecords")
                .whereField("userId", isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("timestamp", isLessThan: Timestamp(date: tomorrow))
                .whereField("recordType", isEqualTo: "study")
                .getDocuments()
            
            let totalTime = querySnapshot.documents.reduce(0.0) { total, doc in
                let data = doc.data()
                let duration = data["duration"] as? TimeInterval ?? 0
                return total + duration
            }
            
            return totalTime > 0 ? totalTime : nil
        } catch {
            return nil
        }
    }
    // 今日すでに投稿しているかチェック
    // hasPostedTodayを改名してgetTodayPostCountに変更
    func getTodayPostCount() async -> Int {
        guard let userId = self.userId else { return 0 }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let querySnapshot = try await db.collection("timelinePosts")
                .whereField("userId", isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("timestamp", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            
            return querySnapshot.documents.count
        } catch {
            print("投稿数チェックエラー: \(error)")
            return 99  // エラー時は安全側に倒す
        }
    }
    
    // 投稿可能かチェック
    func canPostToday() async -> Bool {
        let todayCount = await getTodayPostCount()
        let limit = user?.dailyPostLimit ?? 1
        return todayCount < limit
    }
    // モック投稿データ生成（プレビュー用）
    private func createMockTimelinePosts() -> [TimelinePost] {
        var posts: [TimelinePost] = []
        let calendar = Calendar.current
        
        let mockUsers = [
            ("田中太郎", 15),
            ("鈴木花子", 23),
            ("山田次郎", 8),
            ("佐藤美咲", 42)
        ]
        
        let mockContents = [
            "今日も頑張って3時間勉強できた！明日も継続するぞ💪",
            "レベルアップできて嬉しい！みんなも一緒に頑張ろう✨",
            "数学の問題が解けるようになってきた。基礎って大事だね。",
            "朝活始めました。早起きは三文の徳って本当だった！",
            "プログラミングの勉強楽しい〜！エラーと格闘中だけど😅"
        ]
        
        // 過去5日間の投稿を生成
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let user = mockUsers.randomElement()!
            
            posts.append(TimelinePost(
                id: "mockPost\(i)",
                userId: "mockUser\(i)",
                nickname: user.0,
                content: mockContents[i % mockContents.count],
                timestamp: date,
                level: user.1
            ))
        }
        
        return posts
    }
    // MainViewModel.swift に追加するメソッド
    
    // ⭐️ すべての投稿のニックネームを更新
    func updateNicknameEverywhere(newNickname: String) async throws {
        guard let userId = self.userId else { return }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview { return }
        
        // 1. ユーザー情報を更新
        guard var updatedUser = self.user else { return }
        updatedUser.nickname = newNickname
        self.user = updatedUser
        
        // ユーザー情報を保存
        try await saveUserData(userToSave: updatedUser)
        
        // 2. 自分の全ての投稿を取得して更新
        do {
            // 自分の投稿を全て取得
            let querySnapshot = try await db.collection("timelinePosts")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            // バッチ処理で一括更新
            let batch = db.batch()
            
            for document in querySnapshot.documents {
                let docRef = db.collection("timelinePosts").document(document.documentID)
                batch.updateData(["nickname": newNickname], forDocument: docRef)
            }
            
            // バッチをコミット
            try await batch.commit()
            
            // 3. ローカルの配列も更新
            self.timelinePosts = self.timelinePosts.map { post in
                if post.userId == userId {
                    var updatedPost = post
                    // TimelinePostは構造体なので、新しいインスタンスを作成
                    return TimelinePost(
                        id: post.id,
                        userId: post.userId,
                        nickname: newNickname,  // 新しいニックネーム
                        content: post.content,
                        timestamp: post.timestamp,
                        level: post.level
                    )
                }
                return post
            }
            
            print("✅ すべての投稿のニックネームを更新しました")
            
        } catch {
            print("❌ 投稿の更新エラー: \(error)")
            throw error
        }
    }

    // loadMonthlyDataを実装（studyRecordsから集計）
    
    func loadMonthlyData(for month: Date) async {
        
        guard let userId = self.userId else { return }
        
        
        
        let calendar = Calendar.current
        
        let startOfMonth = calendar.dateInterval(of: .month, for: month)!.start
        
        let endOfMonth = calendar.dateInterval(of: .month, for: month)!.end
        
        
        
        do {
            
            let querySnapshot = try await db.collection("studyRecords")
            
                .whereField("userId", isEqualTo: userId)
            
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))
            
                .whereField("timestamp", isLessThan: Timestamp(date: endOfMonth))
            
                .whereField("recordType", isEqualTo: "study")
            
                .getDocuments()
            
            
            
            // 日付ごとに集計
            
            var dailyData: [Date: TimeInterval] = [:]
            
            for document in querySnapshot.documents {
                
                let data = document.data()
                
                if let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                   
                    let duration = data["duration"] as? TimeInterval {
                    
                    let day = calendar.startOfDay(for: timestamp)
                    
                    dailyData[day] = (dailyData[day] ?? 0) + duration
                    
                }
                
            }
            
            
            
            self.dailyStudyData = dailyData
            
        } catch {
            
            print("月間データ取得エラー: \(error)")
            
        }
        
    }
    
#if DEBUG
    static let mock: MainViewModel = {
        let viewModel = MainViewModel()
        
        viewModel.userId = "mockUserID"
        
        viewModel.user = User(
            id: "mockUserID",
            nickname: "プレビュー太郎",
            level: 10,
            experience: 1200,
            totalStudyTime: 54000,
            rank: 15
        )
        
        viewModel.ranking = [
            User(id: "rank1", nickname: "レベルアップ王", level: 50, experience: 0, totalStudyTime: 1000000, rank: 1),
            User(id: "rank2", nickname: "勉強の達人", level: 48, experience: 0, totalStudyTime: 980000, rank: 2),
            User(id: "rank3", nickname: "努力家さん", level: 45, experience: 0, totalStudyTime: 850000, rank: 3),
            User(id: "rank4", nickname: "コツコツ君", level: 42, experience: 0, totalStudyTime: 720000, rank: 4),
            User(id: "rank5", nickname: "頑張り屋", level: 40, experience: 0, totalStudyTime: 650000, rank: 5),
            User(id: "mockUserID", nickname: "プレビュー太郎", level: 10, experience: 1200, totalStudyTime: 54000, rank: 15),
        ]
        
        viewModel.isLoading = false
        viewModel.errorMessage = nil
        viewModel.timerValue = 0
        viewModel.isTimerRunning = false
        
        return viewModel
    }()
#endif
}
extension MainViewModel {
    func additionalMethod() {
        // 追加メソッドの実装
    }
    
    func anotherMethod() {
        // 別のメソッド
    }
}
