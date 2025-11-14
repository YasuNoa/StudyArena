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
        backgroundTracker.setViewModel(self)
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
            
            // 🔧 ユーザー情報取得後に部門関連データも取得
            print("🏢 部門情報を取得中...")
            await self.loadDepartments()
            await self.fetchUserMemberships()
            print("✅ 部門情報取得完了")
            
            
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
    // MainViewModel.swift の joinDepartment(_ departmentId: String) メソッド内の修正
    
    func joinDepartment(_ departmentId: String) async throws {
        guard let userId = self.userId else { return }
        
        let membership = DepartmentMembership(
            userId: userId,
            departmentId: departmentId,
            departmentName: departments.first { $0.id == departmentId }?.name ?? ""
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
            let beforeLevel = self.user?.level ?? 1
            
            // 経験値を追加
            self.addExperience(from: studyTime)
            // カレンダーに記録
            saveTodayStudyTime(studyTime)
            
            let afterLevel = self.user?.level ?? 1
            let earnedExp = studyTime
            
            // ⭐️ MBTI統計更新を追加
            await self.updateMBTIStatistics(studyTime: studyTime)
            
            // 学習記録を保存
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
            afterLevel: afterLevel,
            mbtiType: user?.mbtiType  // ← 追加
        )
        
        do {
            // シンプルな辞書形式でデータを保存
            let data: [String: Any] = [
                "userId": userId,
                "timestamp": Timestamp(date: Date()),
                "duration": duration,
                "earnedExperience": earnedExp,
                "recordType": recordType.rawValue,
                "beforeLevel": beforeLevel,
                "afterLevel": afterLevel,
                "mbtiType": user?.mbtiType ?? ""  // ← 追加
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
                afterLevel: 10,
                mbtiType: "INTJ"  // ← 追加
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
                    afterLevel: 11 - i/3,
                    mbtiType: "INTJ"  // ← 追加
                ))
            }
        }
        
        return records.sorted { $0.timestamp > $1.timestamp }
    }
    // MainViewModel.swift に追加するコード
    // MainViewModel.swift に追加
    @Published var mbtiStatistics: [String: MBTIStatData] = [:]
    // MainViewModel.swift - loadMBTIStatistics修正版
    func loadMBTIStatistics() async {
        do {
            let doc = try await db.collection("mbtiStatistics")
                .document("global")
                .getDocument()
            
            if let stats = doc.data()?["stats"] as? [String: [String: Any]] {
                // 修正: 明示的に型を指定
                self.mbtiStatistics = stats.compactMapValues { data -> MBTIStatData? in
                    guard let totalTime = data["totalTime"] as? Double,
                          let userCount = data["userCount"] as? Int else {
                        return nil  // 型が明示されているのでnilを返せる
                    }
                    
                    return MBTIStatData(
                        mbtiType: "", // 後で設定
                        totalTime: totalTime,
                        userCount: userCount,
                        avgTime: totalTime / Double(max(userCount, 1))
                    )
                }
                
                // mbtiTypeを設定し直す
                var updatedStats: [String: MBTIStatData] = [:]
                for (mbtiType, statData) in self.mbtiStatistics {
                    var updatedData = statData
                    updatedData = MBTIStatData(
                        mbtiType: mbtiType,
                        totalTime: statData.totalTime,
                        userCount: statData.userCount,
                        avgTime: statData.avgTime
                    )
                    updatedStats[mbtiType] = updatedData
                }
                self.mbtiStatistics = updatedStats
            }
        } catch {
            print("MBTI統計の取得エラー: \(error)")
        }
    }
    // MainViewModel.swift に追加
    func updateMBTIStatistics(studyTime: TimeInterval) async {
        guard let mbti = user?.mbtiType else { return }
        
        // グローバル統計を更新
        let statsRef = db.collection("mbtiStatistics").document("global")
        
        try? await statsRef.updateData([
            "stats.\(mbti).totalTime": FieldValue.increment(Double(studyTime)),
            "stats.\(mbti).userCount": FieldValue.increment(Int64(1))
        ])
    }
    
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
            likeCount: 0,           // ✅ 追加: いいね数を初期化
            likedUserIds: [],       // ✅ 追加: いいねユーザーIDを初期化
            studyDuration: todayStudyTime
        )
        
        do {
            // ✅ 修正: いいね関連フィールドを含める
            let data: [String: Any] = [
                "userId": userId,
                "nickname": user.nickname,
                "content": content,
                "timestamp": Timestamp(date: Date()),
                "level": user.level,
                "likeCount": 0,         // ✅ 追加
                "likedUserIds": [],     // ✅ 追加
                "studyDuration": todayStudyTime ?? NSNull()
            ]
            
            // ✅ 修正: ドキュメントIDを取得して設定
            let docRef = try await db.collection("timelinePosts").addDocument(data: data)
            
            // ローカルの配列にも追加（IDを設定）
            var postWithId = post
            postWithId.id = docRef.documentID
            self.timelinePosts.insert(postWithId, at: 0)
            
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
extension MainViewModel {
    
    // 今日すでにフィードバックを送信しているかチェック
    func hasSubmittedFeedbackToday() async -> Bool {
        guard let userId = self.userId else {
            print("❌ userId が nil です")
            return false
        }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview {
            print("📱 プレビューモード: 制限チェックをスキップ")
            return false
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        print("🔍 フィードバック制限チェック開始")
        print("   - userId: \(userId)")
        print("   - today: \(today)")
        print("   - tomorrow: \(tomorrow)")
        
        do {
            let querySnapshot = try await db.collection("feedbacks")
                .whereField("userId", isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("timestamp", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            
            let count = querySnapshot.documents.count
            print("✅ 今日のフィードバック件数: \(count)")
            
            return count > 0
            
        } catch {
            print("❌ フィードバック制限チェックエラー: \(error)")
            // エラー時は false を返す（送信を許可）
            // ネットワークエラー等でユーザーが困らないように
            return false
        }
    }
    
    // フィードバック送信機能（制限チェック付き）
    func submitFeedback(
        type: String,
        content: String,
        email: String
    ) async throws {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview { return }
        
        // 1日1回制限チェック
        let hasSubmittedToday = await hasSubmittedFeedbackToday()
        if hasSubmittedToday {
            throw NSError(
                domain: "FeedbackError",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "フィードバックは1日1回までです。明日以降に再度お試しください。"]
            )
        }
        
        // メールアドレスのバリデーション
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            throw NSError(domain: "FeedbackError", code: 1, userInfo: [NSLocalizedDescriptionKey: "メールアドレスは必須です"])
        }
        
        guard isValidEmail(trimmedEmail) else {
            throw NSError(domain: "FeedbackError", code: 2, userInfo: [NSLocalizedDescriptionKey: "正しいメールアドレスを入力してください"])
        }
        
        // デバイス情報を取得
        let deviceInfo = getDeviceInfo()
        let appVersion = getAppVersion()
        
        do {
            // Firestoreに保存
            let data: [String: Any] = [
                "userId": self.userId ?? "",
                "userNickname": self.user?.nickname ?? "",
                "userLevel": self.user?.level ?? 1,
                "feedbackType": type,
                "content": content,
                "email": trimmedEmail,
                "timestamp": Timestamp(date: Date()),
                "deviceInfo": deviceInfo,
                "appVersion": appVersion,
                "status": "pending"
            ]
            
            try await db.collection("feedbacks").addDocument(data: data)
            print("✅ フィードバックを送信しました")
            
        } catch {
            print("❌ フィードバック送信エラー: \(error)")
            throw error
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.systemName) \(device.systemVersion) - \(device.model)"
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}

extension MainViewModel {
    
    // MARK: - いいね機能
    
    /// 投稿にいいねを追加/削除
    func toggleLike(for postId: String) async throws -> (isLiked: Bool, newCount: Int) {
        guard let userId = self.userId else {
            throw NSError(domain: "LikeError", code: 1, userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが見つかりません"])
        }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview {
            return (isLiked: true, newCount: Int.random(in: 1...10))
        }
        
        let postRef = db.collection("timelinePosts").document(postId)
        
        return try await withCheckedThrowingContinuation { continuation in
            db.runTransaction({ transaction, errorPointer in
                let postDocument: DocumentSnapshot
                do {
                    postDocument = try transaction.getDocument(postRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                guard postDocument.exists,
                      let postData = postDocument.data() else {
                    let error = NSError(domain: "LikeError", code: 2, userInfo: [NSLocalizedDescriptionKey: "投稿が見つかりません"])
                    errorPointer?.pointee = error
                    return nil
                }
                
                // 現在のいいね情報を取得
                var likedUserIds = postData["likedUserIds"] as? [String] ?? []
                var likeCount = postData["likeCount"] as? Int ?? 0
                
                let isCurrentlyLiked = likedUserIds.contains(userId)
                let newIsLiked: Bool
                let newCount: Int
                
                if isCurrentlyLiked {
                    // いいねを取り消し
                    likedUserIds.removeAll { $0 == userId }
                    likeCount = max(0, likeCount - 1)
                    newIsLiked = false
                    newCount = likeCount
                } else {
                    // いいねを追加
                    likedUserIds.append(userId)
                    likeCount += 1
                    newIsLiked = true
                    newCount = likeCount
                }
                
                // Firestoreを更新
                transaction.updateData([
                    "likedUserIds": likedUserIds,
                    "likeCount": likeCount
                ], forDocument: postRef)
                
                // 戻り値として辞書を返す（強制キャストを避ける）
                return [
                    "isLiked": newIsLiked,
                    "newCount": newCount
                ]
                
            }) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let resultDict = result as? [String: Any],
                          let isLiked = resultDict["isLiked"] as? Bool,
                          let newCount = resultDict["newCount"] as? Int {
                    
                    // ローカルデータも更新
                    Task { @MainActor in
                        self.updateLocalPostLike(postId: postId, isLiked: isLiked, newCount: newCount)
                    }
                    
                    continuation.resume(returning: (isLiked: isLiked, newCount: newCount))
                } else {
                    let unknownError = NSError(domain: "LikeError", code: 3,
                                               userInfo: [NSLocalizedDescriptionKey: "不明なエラー"])
                    continuation.resume(throwing: unknownError)
                }
            }
        }
    }
    // 📝 updateLocalPostLike メソッドも同じextension内に追加（存在しない場合）
    @MainActor
    private func updateLocalPostLike(postId: String, isLiked: Bool, newCount: Int) {
        guard let userId = self.userId,
              let index = timelinePosts.firstIndex(where: { $0.id == postId }) else {
            return
        }
        
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
    
    /// ユーザーが特定の投稿にいいね済みかチェック
    func isPostLikedByUser(_ postId: String) async -> Bool {
        guard let userId = self.userId else { return false }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview { return false }
        
        do {
            let document = try await db.collection("timelinePosts").document(postId).getDocument()
            let likedUserIds = document.data()?["likedUserIds"] as? [String] ?? []
            return likedUserIds.contains(userId)
        } catch {
            print("いいね状態チェックエラー: \(error)")
            return false
        }
    }
    
    /// 投稿のいいね数を取得
    func getLikeCount(for postId: String) async -> Int {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview { return Int.random(in: 0...5) }
        
        do {
            let document = try await db.collection("timelinePosts").document(postId).getDocument()
            return document.data()?["likeCount"] as? Int ?? 0
        } catch {
            print("いいね数取得エラー: \(error)")
            return 0
        }
    }
    
    /// タイムライン投稿をいいね情報付きで読み込み
    func loadTimelinePostsWithLikes() {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreview {
            // プレビュー用のモックデータ（いいね付き）
            self.timelinePosts = createMockTimelinePostsWithLikes()
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
                        var post = try doc.data(as: TimelinePost.self)
                        post.id = doc.documentID
                        return post
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
    
    // MARK: - プライベートメソッド
    
    private func createMockTimelinePostsWithLikes() -> [TimelinePost] {
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
        
        // 過去5日間の投稿を生成（いいね付き）
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let user = mockUsers.randomElement()!
            
            var post = TimelinePost(
                id: "mockPost\(i)",
                userId: "mockUser\(i)",
                nickname: user.0,
                content: mockContents[i % mockContents.count],
                timestamp: date,
                level: user.1
            )
            
            // いいね情報を追加
            post.likeCount = Int.random(in: 0...8)
            post.likedUserIds = (0..<(post.likeCount ?? 0)).map { "user\($0)" }
            
            posts.append(post)
        }
        
        return posts
    }
}
// MainViewModel.swift に追加する通知機能

extension MainViewModel {
    
    // MARK: - 通知関連
    
    func setupNotifications() {
        // 通知権限をリクエスト
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            print("通知権限: \(granted ? "許可" : "拒否")")
        }
        
        // 通知からの学習開始を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startStudyFromNotification),
            name: .startStudyFromNotification,
            object: nil
        )
    }
    
    @objc private func startStudyFromNotification() {
        // 通知から学習開始
        DispatchQueue.main.async {
            if !self.isTimerRunning {
                self.startTimerWithValidation()
            }
        }
    }
    // MainViewModel.swift に追加
    func forceStopTimer() {
        guard isTimerRunning else { return }
        
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        
        // 現在までの時間を記録
        let studyTime = timerValue
        timerValue = 0
        
        // 通常の学習記録として保存
        Task { @MainActor in
            let beforeLevel = self.user?.level ?? 1
            self.addExperience(from: studyTime)
            let afterLevel = self.user?.level ?? 1
            
            // 学習記録保存
            do {
                try await self.saveStudyRecord(
                    duration: studyTime,
                    earnedExp: studyTime,
                    beforeLevel: beforeLevel,
                    afterLevel: afterLevel
                )
                
                guard let userToSave = self.user else { return }
                try await self.saveUserData(userToSave: userToSave)
            } catch {
                print("強制停止時の保存エラー: \(error)")
            }
        }
        
        print("タイマー強制停止: \(Int(studyTime))秒を記録")
    }
    // タイマー停止時に通知送信
    func stopTimerWithNotifications() {
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
            let beforeLevel = self.user?.level ?? 1
            
            // 経験値を追加
            self.addExperience(from: studyTime)
            saveTodayStudyTime(studyTime)
            
            let afterLevel = self.user?.level ?? 1
            let earnedExp = studyTime
            
            // MBTI統計更新
            await self.updateMBTIStatistics(studyTime: studyTime)
            
            // 学習記録を保存
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
            
            // ⭐️ 通知送信
            // 学習完了通知
            NotificationManager.shared.sendStudyCompletedNotification(
                duration: studyTime,
                earnedExp: earnedExp
            )
            
            // レベルアップ通知
            if beforeLevel < afterLevel {
                NotificationManager.shared.sendLevelUpNotification(newLevel: afterLevel)
            }
            
            // 継続日数通知
            if let stats = self.studyStatistics {
                NotificationManager.shared.sendStreakNotification(days: stats.currentStreak)
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
}

// MainViewModel.swift に追加する拡張機能

extension MainViewModel {
    
    // MARK: - Enhanced MBTI Statistics
    
    /// MBTI統計を詳細に読み込む
    func loadDetailedMBTIStatistics() async {
        print("🧠 詳細なMBTI統計を読み込み中...")
        
        do {
            // 1. 全ユーザーのMBTI分布を取得
            let usersSnapshot = try await db.collection("users")
                .whereField("mbtiType", isNotEqualTo: "")
                .getDocuments()
            
            // 2. 学習記録からMBTI別統計を集計
            let recordsSnapshot = try await db.collection("studyRecords")
                .whereField("mbtiType", isNotEqualTo: "")
                .whereField("recordType", isEqualTo: "study")
                .getDocuments()
            
            // 3. 統計を集計
            var mbtiStats: [String: MBTIStatData] = [:]
            
            // ユーザー数を集計
            var userCounts: [String: Int] = [:]
            for document in usersSnapshot.documents {
                if let mbti = document.data()["mbtiType"] as? String, !mbti.isEmpty {
                    userCounts[mbti, default: 0] += 1
                }
            }
            
            // 学習時間を集計
            var totalTimes: [String: Double] = [:]
            var studyCounts: [String: Int] = [:]
            
            for document in recordsSnapshot.documents {
                let data = document.data()
                if let mbti = data["mbtiType"] as? String,
                   let duration = data["duration"] as? TimeInterval,
                   !mbti.isEmpty {
                    totalTimes[mbti, default: 0] += duration
                    studyCounts[mbti, default: 0] += 1
                }
            }
            
            // 4. 統計データを作成
            let allMBTITypes = [
                "INTJ", "INTP", "ENTJ", "ENTP",
                "INFJ", "INFP", "ENFJ", "ENFP",
                "ISTJ", "ISFJ", "ESTJ", "ESFJ",
                "ISTP", "ISFP", "ESTP", "ESFP"
            ]
            
            for mbti in allMBTITypes {
                let userCount = userCounts[mbti] ?? 0
                let totalTime = totalTimes[mbti] ?? 0
                let avgTime = userCount > 0 ? totalTime / Double(userCount) : 0
                
                mbtiStats[mbti] = MBTIStatData(
                    mbtiType: mbti,
                    totalTime: totalTime,
                    userCount: userCount,
                    avgTime: avgTime
                )
            }
            
            await MainActor.run {
                self.mbtiStatistics = mbtiStats
                print("✅ MBTI統計読み込み完了: \(mbtiStats.count)タイプ")
            }
            
        } catch {
            print("❌ MBTI統計読み込みエラー: \(error)")
        }
    }
    
    /// 学習記録保存時にMBTI統計を更新（強化版）
    func updateDetailedMBTIStatistics(studyTime: TimeInterval) async {
        guard let mbti = user?.mbtiType, !mbti.isEmpty else {
            print("⚠️ MBTI未設定のため統計更新をスキップ")
            return
        }
        
        print("📊 MBTI統計更新: \(mbti), 時間: \(studyTime)秒")
        
        // グローバル統計とユーザー別統計を並行更新
        async let globalUpdate = updateGlobalMBTIStatistics(mbti: mbti, studyTime: studyTime)
        async let userUpdate = updateUserMBTIProfile(mbti: mbti, studyTime: studyTime)
        
        do {
            let (_, _) = try await (globalUpdate, userUpdate)
            print("✅ MBTI統計更新完了")
        } catch {
            print("❌ MBTI統計更新エラー: \(error)")
        }
    }
    
    /// グローバルMBTI統計を更新
    private func updateGlobalMBTIStatistics(mbti: String, studyTime: TimeInterval) async throws {
        let statsRef = db.collection("mbtiStatistics").document("global")
        
        try await statsRef.updateData([
            "stats.\(mbti).totalTime": FieldValue.increment(Double(studyTime)),
            "stats.\(mbti).sessionCount": FieldValue.increment(Int64(1)),
            "lastUpdated": Timestamp(date: Date())
        ])
    }
    
    /// ユーザー個別のMBTI学習記録を更新
    private func updateUserMBTIProfile(mbti: String, studyTime: TimeInterval) async throws {
        guard let userId = self.userId else { return }
        
        let userStatsRef = db.collection("userMBTIStats").document(userId)
        
        try await userStatsRef.setData([
            "userId": userId,
            "mbtiType": mbti,
            "totalStudyTime": FieldValue.increment(Double(studyTime)),
            "totalSessions": FieldValue.increment(Int64(1)),
            "lastStudyDate": Timestamp(date: Date()),
            "averageSessionTime": studyTime // これは後で集計時に再計算
        ], merge: true)
    }
    
    /// 月別MBTI統計を取得
    func loadMonthlyMBTIStatistics(for month: Date) async -> [String: MBTIStatData] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)!.start
        let endOfMonth = calendar.dateInterval(of: .month, for: month)!.end
        
        do {
            let recordsSnapshot = try await db.collection("studyRecords")
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))
                .whereField("timestamp", isLessThan: Timestamp(date: endOfMonth))
                .whereField("mbtiType", isNotEqualTo: "")
                .whereField("recordType", isEqualTo: "study")
                .getDocuments()
            
            var monthlyStats: [String: MBTIStatData] = [:]
            var totalTimes: [String: Double] = [:]
            var sessionCounts: [String: Int] = [:]
            
            for document in recordsSnapshot.documents {
                let data = document.data()
                if let mbti = data["mbtiType"] as? String,
                   let duration = data["duration"] as? TimeInterval {
                    totalTimes[mbti, default: 0] += duration
                    sessionCounts[mbti, default: 0] += 1
                }
            }
            
            for mbti in totalTimes.keys {
                let totalTime = totalTimes[mbti] ?? 0
                let sessions = sessionCounts[mbti] ?? 0
                let avgTime = sessions > 0 ? totalTime / Double(sessions) : 0
                
                monthlyStats[mbti] = MBTIStatData(
                    mbtiType: mbti,
                    totalTime: totalTime,
                    userCount: sessions, // 月別では実際にはセッション数
                    avgTime: avgTime
                )
            }
            
            return monthlyStats
            
        } catch {
            print("月別MBTI統計エラー: \(error)")
            return [:]
        }
    }
    
    /// MBTI別の学習パターン分析
    func analyzeMBTILearningPatterns() async -> [String: LearningPattern] {
        do {
            let recordsSnapshot = try await db.collection("studyRecords")
                .whereField("mbtiType", isNotEqualTo: "")
                .whereField("recordType", isEqualTo: "study")
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            var patterns: [String: LearningPattern] = [:]
            var mbtiSessions: [String: [StudySession]] = [:]
            
            // データを整理
            for document in recordsSnapshot.documents {
                let data = document.data()
                if let mbti = data["mbtiType"] as? String,
                   let duration = data["duration"] as? TimeInterval,
                   let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() {
                    
                    let session = StudySession(
                        duration: duration,
                        timestamp: timestamp
                    )
                    
                    mbtiSessions[mbti, default: []].append(session)
                }
            }
            
            // パターンを分析
            for (mbti, sessions) in mbtiSessions {
                patterns[mbti] = analyzeLearningPattern(from: sessions)
            }
            
            return patterns
            
        } catch {
            print("学習パターン分析エラー: \(error)")
            return [:]
        }
    }
    
    /// 個別の学習パターンを分析
    private func analyzeLearningPattern(from sessions: [StudySession]) -> LearningPattern {
        guard !sessions.isEmpty else {
            return LearningPattern(
                averageSessionDuration: 0,
                preferredStudyHour: 0,
                consistencyScore: 0,
                totalSessions: 0
            )
        }
        
        let calendar = Calendar.current
        
        // 平均セッション時間
        let avgDuration = sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count)
        
        // 好む学習時間帯
        let hourCounts: [Int: Int] = sessions.reduce(into: [:]) { result, session in
            let hour = calendar.component(.hour, from: session.timestamp)
            result[hour, default: 0] += 1
        }
        let preferredHour = hourCounts.max(by: { $0.value < $1.value })?.key ?? 0
        
        // 継続性スコア（連続学習日数の標準偏差の逆数）
        let dailySessions = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.timestamp)
        }
        let consistencyScore = calculateConsistencyScore(from: Array(dailySessions.keys))
        
        return LearningPattern(
            averageSessionDuration: avgDuration,
            preferredStudyHour: preferredHour,
            consistencyScore: consistencyScore,
            totalSessions: sessions.count
        )
    }
    
    /// 継続性スコアを計算
    private func calculateConsistencyScore(from studyDates: [Date]) -> Double {
        guard studyDates.count > 1 else { return 0 }
        
        let sortedDates = studyDates.sorted()
        let intervals: [TimeInterval] = zip(sortedDates, sortedDates.dropFirst()).map { $1.timeIntervalSince($0) }
        
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.reduce(0) { sum, interval in
            sum + pow(interval - avgInterval, 2)
        } / Double(intervals.count)
        
        let standardDeviation = sqrt(variance)
        
        // 標準偏差の逆数を正規化（0-1の範囲）
        return standardDeviation > 0 ? min(1.0, 1.0 / (standardDeviation / 86400)) : 1.0
    }
    
    /// トップパフォーマーを取得
    func getTopMBTIPerformers(limit: Int = 5) async -> [MBTIPerformer] {
        var performers: [MBTIPerformer] = []
        
        do {
            // 各MBTIタイプのトップユーザーを取得
            for mbti in ["INTJ", "INTP", "ENTJ", "ENTP", "INFJ", "INFP", "ENFJ", "ENFP",
                         "ISTJ", "ISFJ", "ESTJ", "ESFJ", "ISTP", "ISFP", "ESTP", "ESFP"] {
                
                let usersSnapshot = try await db.collection("users")
                    .whereField("mbtiType", isEqualTo: mbti)
                    .order(by: "totalStudyTime", descending: true)
                    .limit(to: 1)
                    .getDocuments()
                
                if let topUser = usersSnapshot.documents.first {
                    let data = topUser.data()
                    let performer = MBTIPerformer(
                        mbti: mbti,
                        nickname: data["nickname"] as? String ?? "Anonymous",
                        totalStudyTime: data["totalStudyTime"] as? TimeInterval ?? 0,
                        level: data["level"] as? Int ?? 1
                    )
                    performers.append(performer)
                }
            }
            
            return performers.sorted { $0.totalStudyTime > $1.totalStudyTime }
            
        } catch {
            print("トップパフォーマー取得エラー: \(error)")
            return []
        }
    }
    
    /// MBTI統計の初期化（開発・テスト用）
    func initializeMBTIStatistics() async {
        print("🔄 MBTI統計を初期化中...")
        
        let allMBTITypes = [
            "INTJ", "INTP", "ENTJ", "ENTP",
            "INFJ", "INFP", "ENFJ", "ENFP",
            "ISTJ", "ISFJ", "ESTJ", "ESFJ",
            "ISTP", "ISFP", "ESTP", "ESFP"
        ]
        
        let statsRef = db.collection("mbtiStatistics").document("global")
        var initialStats: [String: Any] = [:]
        
        for mbti in allMBTITypes {
            initialStats["stats.\(mbti).totalTime"] = 0.0
            initialStats["stats.\(mbti).userCount"] = 0
            initialStats["stats.\(mbti).sessionCount"] = 0
        }
        
        initialStats["lastUpdated"] = Timestamp(date: Date())
        initialStats["version"] = 1
        
        do {
            try await statsRef.setData(initialStats, merge: true)
            print("✅ MBTI統計初期化完了")
        } catch {
            print("❌ MBTI統計初期化エラー: \(error)")
        }
    }
}

// MARK: - MBTI分析用のデータ構造体

/// 学習セッション
struct StudySession {
    let duration: TimeInterval
    let timestamp: Date
}

/// 学習パターン
struct LearningPattern {
    let averageSessionDuration: TimeInterval // 平均セッション時間
    let preferredStudyHour: Int // 好む学習時間帯（0-23時）
    let consistencyScore: Double // 継続性スコア（0-1）
    let totalSessions: Int // 総セッション数
    
    var formattedAverageSession: String {
        let hours = Int(averageSessionDuration) / 3600
        let minutes = Int(averageSessionDuration) / 60 % 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    var formattedPreferredTime: String {
        return String(format: "%02d:00", preferredStudyHour)
    }
    
    var consistencyRating: String {
        switch consistencyScore {
        case 0.8...:
            return "非常に規則的"
        case 0.6..<0.8:
            return "規則的"
        case 0.4..<0.6:
            return "やや規則的"
        case 0.2..<0.4:
            return "不規則"
        default:
            return "非常に不規則"
        }
    }
}

/// MBTIパフォーマー
struct MBTIPerformer {
    let mbti: String
    let nickname: String
    let totalStudyTime: TimeInterval
    let level: Int
    
    var formattedStudyTime: String {
        let hours = Int(totalStudyTime) / 3600
        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "\(days)日\(remainingHours)時間"
        } else {
            return "\(hours)時間"
        }
    }
}
// MainViewModel.
// MainViewModel.swift の最後のextensionを以下で置き換え
// MainViewModel.swift の修正版（最小限の変更）

// 🔧 既存の最後のextensionを以下で置き換え（重複メソッドを整理）

extension MainViewModel {
    
    // MARK: - 部門関連機能（既存メソッドを活用）
    
    // 🔧 不足メソッド1: ユーザーの参加部門を取得
    func fetchUserMemberships() async {
        guard let userId = self.userId else { return }
        
        do {
            let snapshot = try await db.collection("department_memberships")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            //department_memberships コレクションから、ユーザの所属部門を検索
            print("Userの所属部門情報を取得しました")
            
            await MainActor.run {
                self.userDepartments = snapshot.documents.compactMap { document in
                    try? document.data(as: DepartmentMembership.self)
                }
            }
            print("compactMap でFirestoreドキュメントを `DepartmentMembership` 型に変換self.userDepartments` に格納しました")
        } catch {
            print("ユーザー参加部門取得エラー: \(error)")
        }
    }
    
    // 🔧 不足メソッド2: 特定部門に参加しているかチェック
    func isJoinedDepartment(_ departmentId: String) -> Bool {
        return userDepartments.contains { membership in
            membership.departmentId == departmentId
        }
    }
    
    //  不足メソッド3: 部門作成（2引数版）
    //本番環境では、//user.level >= 1 else {に変更。
    
    func createDepartment(name: String, description: String) async throws {
        guard let user = self.user else {
            throw NSError(domain: "DepartmentError", code: 10,
                          userInfo: [NSLocalizedDescriptionKey: "レベル10以上のユーザーのみ部門を作成できます"])//今回はテスト用で1に設定。
        }
        print("部門作成処理を開始しました")
        
        guard let userId = self.userId else {
            throw NSError(domain: "DepartmentError", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "ユーザー情報が見つかりません"])
        }
        
        let newDepartment = Department(
            name: name,
            description: description,
            creatorName: user.nickname,
            creatorId: userId
        )
        
        do {
            let departmentRef = try await db.collection("departments").addDocument(from: newDepartment)
            
            print("新規部門の追加に成功しました: \(departmentRef.documentID)")
            
            let membership = DepartmentMembership(
                userId: userId,
                departmentId: departmentRef.documentID,
                departmentName: name
            )
            print("メンバー情報を作成")
            
            //コレクションにメンバーシップ情報を保存。document(membership.id)で特定のIDを指定して保存。
            try await db.collection("department_memberships").document(membership.id).setData(from: membership)
            
            // 既存のメソッドを使用
            loadDepartments()
            await fetchUserMemberships()
            
        } catch {
            print("❌ 部門作成エラー: \(error.localizedDescription)")

            throw error
        }
    }
    
    // 🔧 不足メソッド4: 部門参加（Department型版）
    func joinDepartment(_ department: Department) async throws {
        guard let departmentId = department.id else {
            throw NSError(domain: "DepartmentError", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "部門IDが無効です"])
        }
        //まず部門IDがあるかどうか調べる。
        
        guard let userId = self.userId else {
            throw NSError(domain: "DepartmentError", code: 5,
                          userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが見つかりません"])
        }
        //ユーザIDと、自分が使っている端末のIDがあるか＝すでにアカウント作ってるか確認。
        
        let alreadyJoined = userDepartments.contains { membership in
            membership.departmentId == departmentId
        }
        
        guard !alreadyJoined else {
            throw NSError(domain: "DepartmentError", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "既にこの部門に参加しています"])
        }
        
        do {
            let membership = DepartmentMembership(
                userId: userId,
                departmentId: departmentId,
                departmentName: department.name
            )
            //メンバーシップ情報に、部門メンバーとしての情報を入れる。
            //参加していないばあいは、メンバーへ参加。
            try await db.collection("department_memberships").document(membership.id).setData(from: membership)
            print("DBのコレクションにメンバーが追加されました。")
            
            try await db.collection("departments").document(departmentId).updateData([
                "memberCount": FieldValue.increment(Int64(1))
            ])
            print("メンバー数が増えました。")
            
            // 既存のメソッドを使用
            loadDepartments()
            await fetchUserMemberships()
            
        } catch {
            throw error
        }
    }
}
extension MainViewModel {
    
    // MARK: - MBTI設定機能（不足している部分）
    
    /// MBTI を設定・保存する
    func updateMBTIType(_ mbtiType: String?) async throws {
        guard var updatedUser = self.user else {
            throw NSError(domain: "UserError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "ユーザー情報が見つかりません"])
        }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        // ユーザー情報を更新
        updatedUser.mbtiType = mbtiType
        self.user = updatedUser
        
        if !isPreview {
            // Firestoreに保存
            do {
                try await saveUserData(userToSave: updatedUser)
                print("✅ MBTI設定を保存しました: \(mbtiType ?? "未設定")")
            } catch {
                print("❌ MBTI設定保存エラー: \(error)")
                throw error
            }
        }
    }
    
    /// 全MBTIタイプのリストを取得
    static let allMBTITypes = [
        "INTJ", "INTP", "ENTJ", "ENTP",
        "INFJ", "INFP", "ENFJ", "ENFP",
        "ISTJ", "ISFJ", "ESTJ", "ESFJ",
        "ISTP", "ISFP", "ESTP", "ESFP"
    ]
    
    /// MBTI詳細情報を取得
    static func getMBTIInfo(_ type: String) -> (name: String, description: String) {
        switch type {
        case "INTJ": return ("建築家", "独創的で戦略的な思考を持つ完璧主義者")
        case "INTP": return ("論理学者", "知識欲旺盛で革新的な発明家")
        case "ENTJ": return ("指揮官", "大胆で想像力豊かな強力なリーダー")
        case "ENTP": return ("討論者", "賢明で好奇心旺盛な思想家")
        case "INFJ": return ("提唱者", "静かで神秘的だが人々を励ますリーダー")
        case "INFP": return ("仲介者", "詩的で親切、利他的な人")
        case "ENFJ": return ("主人公", "カリスマ的で人々を導くリーダー")
        case "ENFP": return ("広報運動家", "情熱的で創造性豊かな社交家")
        case "ISTJ": return ("管理者", "実用的で事実重視の信頼できる人")
        case "ISFJ": return ("擁護者", "とても献身的で心優しい守護者")
        case "ESTJ": return ("幹部", "優秀な管理者で物事を成し遂げる人")
        case "ESFJ": return ("領事", "非常に思いやりがあり社交的で人気者")
        case "ISTP": return ("巨匠", "大胆で実践的な実験者")
        case "ISFP": return ("冒険家", "柔軟性があり魅力的な芸術家")
        case "ESTP": return ("起業家", "エネルギッシュで認知力がある人")
        case "ESFP": return ("エンターテイナー", "自発的でエネルギッシュな人")
        default: return ("不明", "")
        }
    }
}
