//
//  AuthManager.swift
//  StudyArena
//
//  Created by 田中正造 on 2026/01/10.
//

import Foundation

@Published private var userId: String?
@Published var isLoading: Bool = true


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

