// FeedbackService.swift
import Foundation
import Firebase
import FirebaseFirestore
import UIKit // UIDevice用

class FeedbackService {
    private let db = Firestore.firestore()
    
    func submitFeedback(userId: String, userNickname: String, userLevel: Int, type: String, content: String, email: String) async throws {
        
        // 1日1回制限チェック
        if await hasSubmittedToday(userId: userId) {
            throw NSError(domain: "Feedback", code: 1, userInfo: [NSLocalizedDescriptionKey: "本日の送信上限に達しました"])
        }
        
        let data: [String: Any] = [
            "userId": userId,
            "userNickname": userNickname,
            "userLevel": userLevel,
            "feedbackType": type,
            "content": content,
            "email": email,
            "timestamp": Timestamp(date: Date()),
            "deviceInfo": getDeviceInfo(),
            "appVersion": getAppVersion(),
            "status": "pending"
        ]
        
        try await db.collection("feedbacks").addDocument(data: data)
    }
    
    private func hasSubmittedToday(userId: String) async -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let snapshot = try await db.collection("feedbacks")
                .whereField("userId", isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("timestamp", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            return !snapshot.isEmpty
        } catch {
            return false
        }
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.systemName) \(device.systemVersion) - \(device.model)"
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return version
    }
}
