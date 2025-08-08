import Foundation
import FamilyControls
import DeviceActivity

// スクリーンタイムAPIを使った検証
@MainActor
class ScreenTimeManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var isMonitoring = false
    
    private let center = AuthorizationCenter.shared
    private let deviceActivityCenter = DeviceActivityCenter()
    
    init() {
        Task {
            await checkAuthorization()
        }
    }
    
    // スクリーンタイムへのアクセス許可をリクエスト
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = center.authorizationStatus == .approved
            print("✅ スクリーンタイム認証成功")
        } catch {
            print("❌ スクリーンタイム認証エラー: \(error)")
            isAuthorized = false
        }
    }
    
    // 認証状態の確認
    func checkAuthorization() async {
        isAuthorized = center.authorizationStatus == .approved
        
        if !isAuthorized {
            await requestAuthorization()
        }
    }
    
    // 学習セッション開始時の記録
    func startMonitoring() {
        guard isAuthorized else { return }
        
        isMonitoring = true
        
        // DeviceActivityを使用してアプリの使用状況を監視
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("studySession")
        
        do {
            try deviceActivityCenter.startMonitoring(
                activityName,
                during: schedule
            )
            print("📱 スクリーンタイム監視開始")
        } catch {
            print("❌ 監視開始エラー: \(error)")
        }
    }
    
    // 学習セッション終了時の記録
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        let activityName = DeviceActivityName("studySession")
        deviceActivityCenter.stopMonitoring([activityName])
        
        isMonitoring = false
        print("📱 スクリーンタイム監視終了")
    }
}
