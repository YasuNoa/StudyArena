import Foundation
import UserNotifications
import UIKit

// ⭐️ 修正: NSObjectを継承し、UNUserNotificationCenterDelegateを直接実装
@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var notificationSettings: [NotificationSetting] = []
    
    override init() {
        super.init()  // ⭐️ 追加: NSObjectの初期化
        checkAuthorizationStatus()
        loadDefaultSettings()
        
        // ⭐️ 追加: Delegateを設定
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - 権限管理
    
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("通知権限エラー: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - ローカル通知
    
    /// 学習リマインダー通知をスケジュール
    func scheduleStudyReminder(
        title: String = "📚 学習時間です！",
        body: String = "今日の目標達成のため、勉強を始めましょう！",
        timeComponents: DateComponents,
        identifier: String = "study_reminder"
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // カスタムアクション
        let startAction = UNNotificationAction(
            identifier: "START_STUDY",
            title: "今すぐ開始",
            options: [.foreground]
        )
        
        let laterAction = UNNotificationAction(
            identifier: "LATER",
            title: "後で",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "STUDY_REMINDER",
            actions: [startAction, laterAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "STUDY_REMINDER"
        
        // 繰り返し通知
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: timeComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知スケジュールエラー: \(error)")
            } else {
                print("✅ 通知スケジュール完了: \(identifier)")
            }
        }
    }
    
    /// レベルアップ通知
    func sendLevelUpNotification(newLevel: Int) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 レベルアップ！"
        content.body = "おめでとうございます！レベル\(newLevel)に到達しました！"
        content.sound = .default
        content.badge = 1
        
        // 即座に表示
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "level_up_\(newLevel)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// 学習完了通知
    func sendStudyCompletedNotification(duration: TimeInterval, earnedExp: Double) {
        guard isAuthorized else { return }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        let timeString = hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 学習完了！"
        content.body = "\(timeString)の学習で\(Int(earnedExp))EXPを獲得しました！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "study_completed_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// 継続日数通知
    func sendStreakNotification(days: Int) {
        guard isAuthorized, days > 0, days % 7 == 0 else { return } // 7日ごと
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 素晴らしい継続力！"
        content.body = "\(days)日連続で学習を続けています！この調子で頑張りましょう！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "streak_\(days)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - 通知管理
    
    /// 特定の通知をキャンセル
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }
    
    /// 全ての通知をキャンセル
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// スケジュール済み通知一覧取得
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    // MARK: - 設定管理
    
    private func loadDefaultSettings() {
        notificationSettings = [
            NotificationSetting(
                id: "morning_reminder",
                title: "朝の学習リマインダー",
                description: "毎朝8時に学習を促す通知",
                isEnabled: false,
                time: Calendar.current.dateComponents([.hour, .minute], from: Date())
            ),
            NotificationSetting(
                id: "evening_reminder",
                title: "夕方の学習リマインダー",
                description: "毎夕18時に学習を促す通知",
                isEnabled: false,
                time: Calendar.current.dateComponents([.hour, .minute], from: Date())
            ),
            NotificationSetting(
                id: "study_break",
                title: "休憩リマインダー",
                description: "2時間学習したら休憩を促す通知",
                isEnabled: true,
                time: nil
            )
        ]
    }
    
    func updateNotificationSetting(_ setting: NotificationSetting) {
        if let index = notificationSettings.firstIndex(where: { $0.id == setting.id }) {
            notificationSettings[index] = setting
            
            // 設定に応じて通知をスケジュール/キャンセル
            if setting.isEnabled && setting.time != nil {
                scheduleStudyReminder(
                    timeComponents: setting.time!,
                    identifier: setting.id
                )
            } else {
                cancelNotification(identifier: setting.id)
            }
        }
    }
    
    // ⭐️ 修正: extensionではなく、クラス内でDelegate実装
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "START_STUDY":
            // アプリを開いてタイマー画面に移動
            DispatchQueue.main.async {
                // MainViewModelのタイマー開始処理を呼び出し
                NotificationCenter.default.post(name: .startStudyFromNotification, object: nil)
            }
            
        case "LATER":
            // 30分後に再通知
            scheduleStudyReminder(
                title: "📚 学習リマインダー（再通知）",
                body: "そろそろ学習を始めませんか？",
                timeComponents: Calendar.current.dateComponents(
                    [.hour, .minute],
                    from: Date().addingTimeInterval(1800) // 30分後
                ),
                identifier: "study_reminder_later"
            )
            
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // アプリがフォアグラウンドでも通知を表示
        completionHandler([.banner, .sound])
    }
}

// MARK: - 通知設定データモデル
struct NotificationSetting: Identifiable {
    let id: String
    let title: String
    let description: String
    var isEnabled: Bool
    var time: DateComponents?
}

// MARK: - NotificationCenter Extension
extension Notification.Name {
    static let startStudyFromNotification = Notification.Name("startStudyFromNotification")
}
