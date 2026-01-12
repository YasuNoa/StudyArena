// NotificationManager.swift
import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    // 通知設定（MainViewModelなどで呼ぶ）
    func setup() {
        Task {
            let granted = await requestPermission()
            print("通知権限: \(granted ? "許可" : "拒否")")
        }
    }
    
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    // 通知送信ヘルパー
    func sendStudyCompletedNotification(duration: TimeInterval, earnedExp: Double) {
        let content = UNMutableNotificationContent()
        content.title = "学習完了！"
        content.body = "\(Int(duration / 60))分の学習を記録しました。+\(Int(earnedExp)) EXP"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendLevelUpNotification(newLevel: Int) {
        let content = UNMutableNotificationContent()
        content.title = "レベルアップ！"
        content.body = "レベル \(newLevel) になりました！おめでとうございます🎉"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendStreakNotification(days: Int) {
        let content = UNMutableNotificationContent()
        content.title = "継続記録更新！"
        content.body = "\(days)日連続で学習中です🔥"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension Notification.Name {
    static let startStudyFromNotification = Notification.Name("startStudyFromNotification")
}
