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
        
        // ▼▼▼▼▼ ここからApp Checkを初期化するコードを追加 ▼▼▼▼▼
        // 先ほど作った「設計図」をApp Checkに渡す
        let providerFactory = MyAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        // ▲▲▲▲▲ ここまで追加 ▲▲▲▲▲
        
        FirebaseApp.configure()
        
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
