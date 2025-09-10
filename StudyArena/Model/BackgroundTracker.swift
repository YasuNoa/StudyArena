import SwiftUI
import Combine

class BackgroundTracker: ObservableObject {
    @Published var backgroundTimeExceeded = false
    @Published var isInBackground = false
    @Published var warningMessage: String? = nil
    
    private var backgroundEnteredTime: Date?
    private var totalBackgroundTime: TimeInterval = 0
    private let maxBackgroundTime: TimeInterval = 20
    
    // アプリ切り替えとスリープを区別するためのフラグ
    private var wasActiveBeforeBackground = false
    private var isScreenLocked = false
    
    // MainViewModelへの参照（弱参照で循環参照を防ぐ）
    private weak var viewModel: MainViewModel?
    
    // 🆕 自動停止用タイマー
    private var autoStopTimer: Timer?
    
    init() {
        setupNotifications()
    }
    
    // MainViewModelを設定するメソッド
    func setViewModel(_ viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    private func setupNotifications() {
        // シーンフェーズの変更を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScenePhaseChange),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // 画面ロック検出用
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenLocked),
            name: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenUnlocked),
            name: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil
        )
    }
    
    @objc private func handleScenePhaseChange() {
        wasActiveBeforeBackground = true
    }
    
    @objc private func handleDidBecomeActive() {
        // 🆕 自動停止タイマーを停止
        stopAutoStopTimer()
        
        if isInBackground {
            if let enteredTime = backgroundEnteredTime {
                let backgroundDuration = Date().timeIntervalSince(enteredTime)
                
                if !isScreenLocked {
                    totalBackgroundTime += backgroundDuration
                    checkBackgroundTime()
                }
            }
            isInBackground = false
            backgroundEnteredTime = nil
        }
        wasActiveBeforeBackground = false
        isScreenLocked = false
    }
    
    @objc private func handleDidEnterBackground() {
        if !isScreenLocked {
            isInBackground = true
            backgroundEnteredTime = Date()
            
            // 🆕 自動停止タイマーを開始
            startAutoStopTimer()
            
            print("⚠️ アプリがバックグラウンドに移行しました（自動停止タイマー開始）")
        }
    }
    
    @objc private func handleWillEnterForeground() {
        // ここでは特に処理しない（handleDidBecomeActiveで処理）
    }
    
    @objc private func handleScreenLocked() {
        isScreenLocked = true
        print("🔒 画面がロックされました（カウント停止）")
        
        // 🆕 画面ロック時は自動停止タイマーも停止
        stopAutoStopTimer()
        
        if isInBackground && backgroundEnteredTime != nil {
            backgroundEnteredTime = nil
        }
    }
    
    @objc private func handleScreenUnlocked() {
        isScreenLocked = false
        print("🔓 画面のロックが解除されました")
        
        if isInBackground && backgroundEnteredTime == nil {
            backgroundEnteredTime = Date()
            // 🆕 画面ロック解除後もバックグラウンドなら自動停止タイマー再開
            startAutoStopTimer()
        }
    }
    
    // 🆕 自動停止タイマーを開始
    private func startAutoStopTimer() {
        // 既存のタイマーがあれば停止
        stopAutoStopTimer()
        
        // タイマーが動いているかチェック（メインアクター上で実行）
        Task { @MainActor in
            guard self.viewModel?.isTimerRunning == true else { return }
            
            self.autoStopTimer = Timer.scheduledTimer(withTimeInterval: self.maxBackgroundTime, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.handleAutoStop()
                }
            }
            
            print("⏰ 自動停止タイマー開始（\(Int(self.maxBackgroundTime))秒後に停止）")
        }
    }
    
    // 🆕 自動停止タイマーを停止
    private func stopAutoStopTimer() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
    }
    
    // 🆕 自動停止処理
    private func handleAutoStop() {
        print("⏹️ バックグラウンド時間超過により自動停止")
        
        backgroundTimeExceeded = true
        warningMessage = "他のアプリを\(Int(maxBackgroundTime))秒間使用したため、学習タイマーを自動停止しました。"
        
        // MainViewModelのタイマーを強制停止（メインアクター上で実行）
        Task { @MainActor in
            self.viewModel?.forceStopTimer()
        }
        
        // 🆕 通知を送信
        sendBackgroundTimeoutNotification()
    }
    
    // 🆕 バックグラウンド時間超過通知
    private func sendBackgroundTimeoutNotification() {
        let content = UNMutableNotificationContent()
        content.title = "学習タイマー自動停止"
        content.body = "他のアプリを\(Int(maxBackgroundTime))秒間使用したため、タイマーを停止しました。"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "backgroundTimeout",
            content: content,
            trigger: nil // 即座に通知
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知送信エラー: \(error)")
            }
        }
    }
    
    private func checkBackgroundTime() {
        if totalBackgroundTime > maxBackgroundTime {
            backgroundTimeExceeded = true
            warningMessage = "他のアプリを\(Int(totalBackgroundTime))秒間使用していました。学習への集中を保つため、今回のセッションは記録されません。"
            print("❌ バックグラウンド時間超過: \(totalBackgroundTime)秒")
        } else if totalBackgroundTime > maxBackgroundTime * 0.5 {
            warningMessage = "注意: 他のアプリを\(Int(totalBackgroundTime))秒間使用しています。\(Int(maxBackgroundTime))秒を超えると記録されません。"
            print("⚠️ バックグラウンド時間警告: \(totalBackgroundTime)秒")
        }
    }
    
    func resetSession() {
        // 🆕 自動停止タイマーも停止
        stopAutoStopTimer()
        
        backgroundTimeExceeded = false
        isInBackground = false
        backgroundEnteredTime = nil
        totalBackgroundTime = 0
        warningMessage = nil
        wasActiveBeforeBackground = false
        isScreenLocked = false
        print("🔄 バックグラウンドトラッカーをリセットしました")
    }
    
    func getCurrentBackgroundTime() -> TimeInterval {
        if let enteredTime = backgroundEnteredTime, !isScreenLocked {
            return totalBackgroundTime + Date().timeIntervalSince(enteredTime)
        }
        return totalBackgroundTime
    }
    
    deinit {
        stopAutoStopTimer()
        NotificationCenter.default.removeObserver(self)
    }
}
