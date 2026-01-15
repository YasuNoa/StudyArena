// AuthManager.swift
import Foundation
import Combine
import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var userId: String?
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    // シングルトン化のためprivate init
    private init() {}
    
    func signInAnonymously() {
        print("🔥 Firebase Auth の状態を確認中...")
        isLoading = true
        
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ 認証エラー: \(error.localizedDescription)")
                    self?.errorMessage = "認証に失敗しました: \(error.localizedDescription)"
                    return
                }
                
                if let authUser = authResult?.user {
                    print("✅ 認証成功! UID: \(authUser.uid)")
                    self?.userId = authUser.uid
                }
            }
        }
    }
    
    func retryAuthentication() {
        signInAnonymously()
    }
}
