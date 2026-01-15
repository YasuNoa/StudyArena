// NotificationManager.swift
import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    @Published var notificationSettings: [NotificationSetting] = [
        NotificationSetting(id: "study_reminder", title: "学習リマインダー", description: "毎日の学習時間を知らせます", isEnabled: true, time: DateComponents(hour: 20, minute: 0)),
        NotificationSetting(id: "level_up", title: "レベルアップ通知", description: "レベルアップ時に通知します", isEnabled: true),
        NotificationSetting(id: "streak", title: "継続記録通知", description: "継続日数の記録更新を知らせます", isEnabled: true)
    ]
    
    private init() {
        Task {
            await checkPermission()
        }
    }
    
    func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        DispatchQueue.main.async {
            self.isAuthorized = (settings.authorizationStatus == .authorized)
        }
    }
    
    // 通知設定（MainViewModelなどで呼ぶ）
    func setup() {
        Task {
            let granted = await requestPermission()
            print("通知権限: \(granted ? "許可" : "拒否")")
            await checkPermission()
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
    
    // 設定更新
    func updateNotificationSetting(_ setting: NotificationSetting) {
        if let index = notificationSettings.firstIndex(where: { $0.id == setting.id }) {
            notificationSettings[index] = setting
            // ここでUserDefaultsへの保存や、通知スケジュールの再設定を行うとGood
            print("通知設定更新: \(setting.title) -> \(setting.isEnabled)")
        }
    }
}

extension Notification.Name {
    static let startStudyFromNotification = Notification.Name("startStudyFromNotification")
}
