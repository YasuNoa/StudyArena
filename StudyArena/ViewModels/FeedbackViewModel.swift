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
    
    private let service = FeedbackService()
    
    func checkDailyLimit(userId: String) async {
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
    
    func submitFeedback(userId: String, userNickname: String, userLevel: Int, type: String, content: String, email: String) async throws {
        isSubmitting = true
        errorMessage = nil
        
        do {
            try await service.submitFeedback(
                userId: userId,
                userNickname: userNickname,
                userLevel: userLevel,
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
