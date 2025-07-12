// FileName: producteneApp.swift

import SwiftUI
import FirebaseCore
import FirebaseAppCheck // ▼▼▼ 追加 ▼▼▼

// ▼▼▼▼▼ ここからApp Checkの「設計図」クラスをまるごと追加 ▼▼▼▼▼
class MyAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
#if targetEnvironment(simulator)
        // シミュレータで実行している場合は、デバッグ用のプロバイダを返す
        return AppCheckDebugProvider(app: app)
#else
        // 実機で実行している場合は、DeviceCheckのプロバイダを返す
        return AppAttestProvider(app: app)
#endif
    }
}
// ▲▲▲▲▲ ここまで追加 ▲▲▲▲▲


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        print("🚀 AppDelegate: アプリ起動")
        
        // Firebase設定
        FirebaseApp.configure()
        print("🔥 Firebase が初期化されました")
        
        // Firebase Authの状態を確認
        if let app = FirebaseApp.app() {
            print("✅ FirebaseApp: \(app.name)")
            print("   - ProjectID: \(app.options.projectID ?? "なし")")
        } else {
            print("❌ FirebaseApp が nil です！")
        }
        
        return true
    }
}
@main
struct ProducteneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            // ContentView()を直接表示するように修正
            ContentView()
        }
    }
}
