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
    
    init() {
        authenticateUser()
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
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    self.handleError("認証に失敗しました", error: error)
                    return
                }
                
                guard let authUser = authResult?.user else {
                    self.handleError("認証に失敗しました", error: nil)
                    return
                }
                
                self.userId = authUser.uid
                await self.loadUserData(uid: authUser.uid)
            }
        }
    }
    
    private func loadUserData(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            if document.exists {
                var loadedUser = try document.data(as: User.self)
                loadedUser.id = uid
                
                // 初回ユーザーなどでニックネームが空の場合、デフォルト値を設定
                if loadedUser.nickname.isEmpty {
                    loadedUser.nickname = "挑戦者"
                    try await self.saveUserData(userToSave: loadedUser)
                }
                
                self.user = loadedUser
                
            } else {
                // 新規ユーザーのドキュメント作成
                var newUser = User(id: uid, nickname: "挑戦者")
                self.user = newUser
                try await self.saveUserData(userToSave: newUser)
            }
            
            self.isLoading = false
            
        } catch {
            self.handleError("ユーザーデータのロードに失敗しました", error: error)
        }
    }
    
    // MARK: - Data Persistence
    func saveUserData(userToSave: User) async throws {
        guard let uid = self.userId else {
            throw NSError(domain: "UserDataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが見つかりません"])
        }
        
        do {
            try await db.collection("users").document(uid).setData(from: userToSave, merge: true)
        } catch {
            throw error
        }
    }
    
    // MARK: - Ranking
    func loadRanking() {
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
}
