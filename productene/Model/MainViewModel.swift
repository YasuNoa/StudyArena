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
    
    @Published var availablePersons: [GreatPerson] = []
    @Published var currentPartner: GreatPerson?
    
    @Published var timerValue: TimeInterval = 0
    @Published var isTimerRunning: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var userId: String?
    private var timer: Timer?
    
    init() {
        setupFirestore()
        loadGreatPersons()
        authenticateUser()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func setupFirestore() {
        let settings = FirestoreSettings()
        // キャッシュ設定（デフォルトで有効になっているので、特に設定する必要はない）
        // 明示的に設定する場合は以下のようにする：
        // settings.cacheSettings = MemoryCacheSettings()
        // または
        // settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }
    
    // MARK: - Authentication & Data Loading
    func retryAuthentication() {
        authenticateUser()
    }
    
    private func authenticateUser() {
        isLoading = true
        errorMessage = nil
        
        // Firebaseアプリの状態を確認
        if FirebaseApp.app() == nil {
            print("⚠️ Firebase未初期化")
            self.handleError("Firebaseが初期化されていません", error: nil)
            return
        }
        
        print("🔄 認証開始...")
        print("📱 Firebase App Name: \(FirebaseApp.app()?.name ?? "Unknown")")
        print("🔧 Firebase Options: \(FirebaseApp.app()?.options.description ?? "No options")")
        
        // 現在の認証状態を確認
        if let currentUser = Auth.auth().currentUser {
            print("✅ 既存ユーザーが見つかりました: \(currentUser.uid)")
            print("👤 匿名ユーザー: \(currentUser.isAnonymous)")
        } else {
            print("🆕 新規ユーザーとして認証を開始します")
        }
        
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ 認証エラー詳細: \(error)")
                    print("エラーコード: \((error as NSError).code)")
                    print("エラードメイン: \((error as NSError).domain)")
                    print("エラー情報: \((error as NSError).userInfo)")
                    
                    // エラーコードによる詳細な分析
                    let errorCode = (error as NSError).code
                    switch errorCode {
                    case 17020:
                        print("💡 エラー原因: ネットワーク接続の問題")
                    case 17999:
                        print("💡 エラー原因: 内部エラー - Firebaseの設定を確認してください")
                    case 17015:
                        print("💡 エラー原因: 匿名認証が無効になっています")
                    default:
                        print("💡 不明なエラーコード: \(errorCode)")
                    }
                    
                    self.handleError("認証に失敗しました", error: error)
                    return
                }
                
                guard let authUser = authResult?.user else {
                    print("❌ 認証結果にユーザー情報が含まれていません")
                    self.handleError("認証に失敗しました", error: nil)
                    return
                }
                
                self.userId = authUser.uid
                print("✅ ユーザー認証成功!")
                print("🆔 ユーザーID: \(authUser.uid)")
                print("👤 匿名ユーザー: \(authUser.isAnonymous)")
                print("📅 作成日時: \(authUser.metadata.creationDate?.description ?? "不明")")
                
                await self.loadUserData(uid: authUser.uid)
            }
        }
    }
    
    private func loadGreatPersons() {
        let nobunaga = GreatPerson(
            id: "nobunaga",
            name: "織田信長",
            description: "天下統一を目指した風雲児。",
            imageName: "person.crop.circle.fill",
            skill: Skill(name: "天下布武", effect: .expBoost, value: 1.1)
        )
        
        let einstein = GreatPerson(
            id: "einstein",
            name: "アインシュタイン",
            description: "相対性理論を提唱した天才物理学者。",
            imageName: "brain.head.profile",
            skill: Skill(name: "相対性理論", effect: .expBoost, value: 1.2)
        )
        
        self.availablePersons = [nobunaga, einstein]
    }
    
    private func loadUserData(uid: String) async {
        print("📊 ユーザーデータの読み込み開始...")
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            if document.exists {
                print("✅ 既存のユーザーデータが見つかりました")
                var loadedUser = try document.data(as: User.self)
                loadedUser.id = uid // DocumentIDが正しく設定されるように
                self.user = loadedUser
                print("📊 ユーザーデータ詳細:")
                print("   - ニックネーム: \(loadedUser.nickname)")
                print("   - レベル: \(loadedUser.level)")
                print("   - 総学習時間: \(formatTime(loadedUser.totalStudyTime))")
                print("   - 解放済み偉人数: \(loadedUser.unlockedPersonIDs.count)")
            } else {
                print("🆕 新規ユーザーです。デフォルトデータを作成します。")
                var newUser = User()
                newUser.id = uid
                
                // デフォルトで織田信長を解放
                if let nobunagaId = self.availablePersons.first(where: { $0.name == "織田信長" })?.id {
                    newUser.unlockedPersonIDs.append(nobunagaId)
                    print("🎁 織田信長を初期偉人として解放しました")
                }
                
                self.user = newUser
                try await self.saveUserData()
            }
            
            self.setupPartner()
            self.isLoading = false
            print("✅ すべての初期化が完了しました")
            
        } catch {
            print("❌ Firestoreエラー詳細: \(error)")
            print("エラータイプ: \(type(of: error))")
            if let firestoreError = error as NSError? {
                print("エラーコード: \(firestoreError.code)")
                print("エラードメイン: \(firestoreError.domain)")
            }
            self.handleError("ユーザーデータのロードに失敗しました", error: error)
        }
    }
    
    private func setupPartner() {
        if let firstUnlockedId = user?.unlockedPersonIDs.first,
           let partner = availablePersons.first(where: { $0.id == firstUnlockedId }) {
            self.currentPartner = partner
            print("🤝 パートナー設定: \(partner.name)")
        }
    }
    
    // MARK: - Data Persistence
    func saveUserData() async throws {
        guard let user = user, let uid = userId else {
            throw NSError(domain: "UserDataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "ユーザーデータまたはUIDが見つかりません"])
        }
        
        do {
            try await db.collection("users").document(uid).setData(from: user, merge: true)
            print("💾 ユーザーデータを保存しました。")
        } catch {
            print("❌ データ保存エラー: \(error)")
            throw error
        }
    }
    
    // MARK: - Ranking
    func loadRanking() {
        print("🏆 ランキングデータの取得開始...")
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
                        user.id = doc.documentID // DocumentIDを確実に設定
                        rank += 1
                        return user
                    } catch {
                        print("⚠️ ランキングデータの解析エラー: \(error)")
                        return nil
                    }
                }
                print("✅ ランキングを更新しました。(\(self.ranking.count)件)")
                
            } catch {
                print("❌ ランキング取得エラー: \(error)")
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
        print("⏱️ タイマー開始")
    }
    
    func stopTimer() {
        guard isTimerRunning else { return }
        
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        
        let studyTime = timerValue
        timerValue = 0
        
        print("⏹️ タイマー停止 - 学習時間: \(formatTime(studyTime))")
        
        Task { @MainActor in
            self.addExperience(from: studyTime)
            
            do {
                try await self.saveUserData()
            } catch {
                self.handleError("データの保存に失敗しました", error: error)
            }
        }
    }
    
    private func addExperience(from studyTime: TimeInterval) {
        guard var user = self.user else { return }
        
        var earnedExp = studyTime
        if let partner = currentPartner, partner.skill.effect == .expBoost {
            earnedExp *= partner.skill.value
            print("🎯 スキル効果適用: \(partner.skill.name) - 経験値 \(String(format: "%.0f", (partner.skill.value - 1) * 100))% UP")
        }
        
        user.experience += earnedExp
        user.totalStudyTime += studyTime
        
        print("⭐ 獲得経験値: \(Int(earnedExp))")
        
        var leveledUp = false
        while user.experience >= user.experienceForNextLevel {
            user.experience -= user.experienceForNextLevel
            user.level += 1
            leveledUp = true
            checkAndUnlockPerson(for: &user)
        }
        
        self.user = user
        
        if leveledUp {
            print("🎉 レベルアップ！現在のレベル: \(user.level)")
        }
    }
    
    private func checkAndUnlockPerson(for user: inout User) {
        if user.level >= 3,
           let einsteinId = availablePersons.first(where: { $0.name == "アインシュタイン" })?.id,
           !user.unlockedPersonIDs.contains(einsteinId) {
            user.unlockedPersonIDs.append(einsteinId)
            print("🎉 新たな偉人、アインシュタインを解放しました！")
        }
    }
    
    // MARK: - Partner Logic
    func setPartner(_ person: GreatPerson) {
        self.currentPartner = person
        print("🤝 パートナーを\(person.name)に設定しました")
    }
    
    // MARK: - Helpers
    private func handleError(_ message: String, error: Error?) {
        let detailedMessage = error != nil ? "\(message): \(error!.localizedDescription)" : message
        print("🚨 エラー: \(detailedMessage)")
        self.errorMessage = detailedMessage
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
}
