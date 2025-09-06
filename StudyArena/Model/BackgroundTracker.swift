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
    
    init() {
        setupNotifications()
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
        // アプリが非アクティブになる（コントロールセンター、通知センター、画面ロックなど）
        wasActiveBeforeBackground = true
    }
    
    @objc private func handleDidBecomeActive() {
        // アプリがアクティブに戻った
        if isInBackground {
            // バックグラウンドから復帰
            if let enteredTime = backgroundEnteredTime {
                let backgroundDuration = Date().timeIntervalSince(enteredTime)
                
                // スリープ状態だった場合は加算しない
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
        // アプリが完全にバックグラウンドへ（他のアプリに切り替えた場合）
        if !isScreenLocked {
            // 画面ロックではなく、アプリ切り替えの場合のみカウント開始
            isInBackground = true
            backgroundEnteredTime = Date()
            print("⚠️ アプリがバックグラウンドに移行しました（カウント開始）")
        }
    }
    
    @objc private func handleWillEnterForeground() {
        // アプリがフォアグラウンドに戻る直前
        // ここでは特に処理しない（handleDidBecomeActiveで処理）
    }
    
    @objc private func handleScreenLocked() {
        // 画面がロックされた
        isScreenLocked = true
        print("🔒 画面がロックされました（カウント停止）")
        
        // 画面ロック時はバックグラウンド時間をカウントしない
        if isInBackground && backgroundEnteredTime != nil {
            // 一時的にバックグラウンド計測を停止
            backgroundEnteredTime = nil
        }
    }
    
    @objc private func handleScreenUnlocked() {
        // 画面のロックが解除された
        isScreenLocked = false
        print("🔓 画面のロックが解除されました")
        
        // アプリがバックグラウンドにいる場合は計測を再開
        if isInBackground && backgroundEnteredTime == nil {
            backgroundEnteredTime = Date()
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
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - View Modifier for Scene Phase Tracking
struct BackgroundTrackingModifier: ViewModifier {
    @EnvironmentObject var backgroundTracker: BackgroundTracker
    @Environment(\.scenePhase) var scenePhase
    @State private var lastPhase: ScenePhase = .active
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                print("📱 バックグラウンド追跡を開始")
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handlePhaseChange(from: oldPhase, to: newPhase)
            }
    }
    
    private func handlePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        print("📱 Scene Phase: \(oldPhase) → \(newPhase)")
        
        switch (oldPhase, newPhase) {
        case (.active, .inactive):
            // アクティブ → 非アクティブ（コントロールセンターや通知センターを開いた、電源ボタンを押した）
            print("⏸ アプリが非アクティブになりました")
            
        case (.inactive, .background):
            // 非アクティブ → バックグラウンド（他のアプリに切り替えた）
            print("🔄 他のアプリに切り替えました")
            
        case (.inactive, .active):
            // 非アクティブ → アクティブ（電源ボタンでのスリープから復帰、通知センターを閉じた）
            print("▶️ アプリに戻りました（スリープ解除または通知センターから）")
            
        case (.background, .inactive):
            // バックグラウンド → 非アクティブ（アプリスイッチャーを表示）
            print("📱 アプリスイッチャー表示中")
            
        case (.background, .active):
            // バックグラウンド → アクティブ（アプリに戻ってきた）
            print("✅ アプリがフォアグラウンドに復帰")
            
        default:
            print("📱 その他の遷移: \(oldPhase) → \(newPhase)")
        }
        
        lastPhase = newPhase
    }
}
