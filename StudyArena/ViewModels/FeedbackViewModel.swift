//
//  FeedbackViewModel.swift
//  StudyArena
//
//  Created by 田中正造 on 2026/01/16.
//

import Combine
import Foundation

@MainActor
class FeedbackViewModel: ObservableObject {
    @Published var hasSubmittedToday = false
    @Published var isCheckingLimit = true
    @Published var limitCheckError: String? = nil
    @Published var isSubmitting = false
    @Published var errorMessage: String? = nil
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    
    // 親から受け取る情報
    var user: User? {
        didSet {
            userId = user?.id
        }
    }
    private(set) var userId: String?
    
    private let service = FeedbackService()
    
    func checkDailyLimit() async {
        guard let userId = userId else { return }
        
        isCheckingLimit = true
        limitCheckError = nil
        
        do {
            let hasSubmitted = await service.hasSubmittedToday(userId: userId)
            hasSubmittedToday = hasSubmitted
        } catch {
            // hasSubmittedToday自体はエラーを投げないが、将来的にエラーハンドリングが必要な場合
            limitCheckError = "制限の確認に失敗しました: \(error.localizedDescription)"
        }
        
        isCheckingLimit = false
    }
    
    func submitFeedback(type: String, content: String, email: String) async throws {
        guard let userId = userId, let user = user else {
            throw NSError(domain: "FeedbackError", code: 401, userInfo: [NSLocalizedDescriptionKey: "ユーザー情報が見つかりません"])
        }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            try await service.submitFeedback(
                userId: userId,
                userNickname: user.nickname,
                userLevel: user.level,
                type: type,
                content: content,
                email: email
            )
            showSuccessAlert = true
            hasSubmittedToday = true // 送信成功したら制限フラグを立てる
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
            throw error
        }
        
        isSubmitting = false
    }
    
    // Future requirement placeholder if needed
    func loadMonthlyData() {
        // 現在は使用していないが、インターフェース整合性のために定義
        // 必要に応じて実装
    }
}
