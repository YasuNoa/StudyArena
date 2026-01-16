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
    // @Published var ranking: [User] = [] // RankingViewModelへ移動
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var validationWarning: String?

    // シングルトンだが、objectWillChangeを監視するために保持
    private let timerManager = TimerManager.shared
    private let authManager = AuthManager.shared
    private let userService = UserService()
    private let studyRecordService = StudyRecordService()
    private let feedbackService = FeedbackService()
    
    private var cancellables = Set<AnyCancellable>()
    
    
    init() {
        print("🚀 MainViewModel Initialized")
        
        setupAuthBinding()
        setupTimerBinding()
        setupNotifications() // 通知の監視開始
        
        // アプリ起動時に認証開始
        authManager.signInAnonymously()
    }
    
    deinit {
        print("🗑️ MainViewModel Deinitialized")
    }
    
    // MARK: - Bindings (連携設定)
    
    private func setupAuthBinding() {
        // AuthManagerのuserIdが変わったら、ユーザーデータを読み込みに行く
        authManager.$userId
            .receive(on: RunLoop.main)
            .sink { [weak self] userId in
                guard let self = self, let userId = userId else { return }
                Task {
                    await self.loadUserData(uid: userId)
                }
            }
            .store(in: &cancellables)
        
        // エラーメッセージの連携
        authManager.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
        
        // ロード状態の連携
        authManager.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    private func setupTimerBinding() {
        // 1. TimerManagerの変更をMainViewModelの変更として転送 (objectWillChangeの連結)
        timerManager.objectWillChange //TimerManagerの中にある値が変わる直前を検知するセンサ。
            .sink { [weak self] _ in //ここがサブスクライブ。{}の処理を実行する。objectwillchangeで検知されたら{}を実行。
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        // TimerManagerの警告をMainViewModelに反映
        timerManager.$validationWarning
            .assign(to: \.validationWarning, on: self)
            .store(in: &cancellables)
        
        // タイマー完了時の処理（Combine）
        timerManager.timerCompletedSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] studyTime in
                self?.handleStudyCompleted(studyTime: studyTime)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 学習完了時の処理 (司令塔の仕事)
    private func handleStudyCompleted(studyTime: TimeInterval) {
        guard let userId = authManager.userId else { return }
        
        Task {
            print("✅ 学習完了: \(Int(studyTime))秒 - 保存処理を開始します")
            
            // 1. 経験値付与 & ユーザー更新 (UserService)
            // ※ addExperience内でレベルアップ判定や保存も行う想定
            await userService.updateExperience(userId: userId, amount: studyTime)
            
            // 2. 学習記録の保存 (StudyService)
            let record = StudyRecord(
                userId: userId,
                timestamp: Date(),
                duration: studyTime,
                earnedExperience: studyTime, // シンプルに1秒1EXPとする場合
                recordType: .study,
                beforeLevel: user?.level ?? 1,
                afterLevel: user?.level ?? 1, // updateExperienceの結果を反映すべきだが一旦簡易実装
                mbtiType: user?.mbtiType
            )
            try? await studyRecordService.saveStudyRecord(record)
            
            // 3. 画面の更新（ユーザー情報再取得）
            await loadUserData(uid: userId)
            
            // 4. 通知送信
            NotificationManager.shared.sendStudyCompletedNotification(
                duration: studyTime,
                earnedExp: studyTime
            )
        }
    }
    
    // MARK: - ユーザー管理 (UserServiceへの委譲)
    
    func loadUserData(uid: String) async {
        // isLoadingの制御はUserService側に任せるか、ここでするか統一する
        // 今回はAuthManagerと連携しているので、ここではシンプルに呼ぶ
        do {
            self.user = try await userService.fetchUser(uid: uid)
            // ランキングもついでに更新
            // ランキングもついでに更新 (RankingView側でやるので削除)
            // loadRanking()
        } catch {
            print("ユーザーロードエラー: \(error)")
        }
    }
    
    // RankingViewModelへ移動済
    /*
    func loadRanking() {
        Task {
            self.ranking = await userService.loadRanking()
        }
    }
     */
    
    func updateNicknameEverywhere(newNickname: String) async throws {
        guard let userId = authManager.userId else { return }
        
        // 1. UserServiceでユーザー情報更新
        try await userService.updateNickname(userId: userId, name: newNickname)
        
        // 2. TimelineServiceで過去の投稿も更新
        let timelineService = TimelineService()
        try await timelineService.updateNicknameInAllPosts(userId: userId, newNickname: newNickname)
        
        // 3. ローカルのユーザー情報を更新して再描画
        await loadUserData(uid: userId)
    }
    

    
    
    // Viewで `viewModel.timerValue` を参照している場合用
    var timerValue: TimeInterval {
        timerManager.timerValue
    }
    
    // Viewで `viewModel.isTimerRunning` を参照している場合用
    var isTimerRunning: Bool {
        timerManager.isTimerRunning
    }
    
    func startTimer() {
        timerManager.startTimer()
    }
    
    func stopTimer() {
        timerManager.stopTimer()
    }
    
    func stopTimerWithNotifications() {
        // 名前は違ってもやることは同じなら、Managerのメソッドを呼ぶ
        timerManager.stopTimer()
    }
    
    func forceStopTimer() {
        timerManager.forceStop()
    }
    
    // 認証リトライ
    func retryAuthentication() {
        authManager.retryAuthentication()
    }
    
    // フィードバック送信
    func submitFeedback(type: String, content: String, email: String) async throws {
        // user情報を付与して送る
        try await feedbackService.submitFeedback(
            userId: authManager.userId ?? "",
            userNickname: user?.nickname ?? "",
            userLevel: user?.level ?? 1,
            type: type,
            content: content,
            email: email
        )
    }
    
    // MARK: - 通知関連
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startStudyFromNotification),
            name: .startStudyFromNotification,
            object: nil
        )
    }
    
    @objc private func startStudyFromNotification() {
        print("📩 通知から学習開始")
        DispatchQueue.main.async {
            self.timerManager.startTimer()
        }
    }
    
    // MARK: - Helpers
    func formatTime(_ interval: TimeInterval) -> String {
        return TimerManager.shared.formatTime(interval)
    }
}

// MainViewModel.swift の一番下に追加
#if DEBUG
extension MainViewModel {
    static let mock: MainViewModel = {
        let vm = MainViewModel()
        let mockUserId = "mock-user-id"
        
        // 1. DepartmentMembership の作成
        // 定義に合わせて userId, departmentId, departmentName だけを渡します
        let mockMembership = DepartmentMembership(
            userId: mockUserId,
            departmentId: "dept-mock-1",
            departmentName: "プレビュー部門",
            role: .member
        )
        
        // 2. User の作成
        // departments には配列として渡します
        vm.user = User(
            id: mockUserId,
            nickname: "プレビュー太郎",
            level: 10,
            experience: 500,
            totalStudyTime: 12000,
            departments: [mockMembership], // ✅ ここで配列にする
            mbtiType: "INTJ"
        )
        
        vm.isLoading = false
        
        return vm
    }()
}
#endif
