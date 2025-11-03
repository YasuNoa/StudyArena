# StudyArena

StudyArenaは、学習時間を記録・管理し、他のユーザーと競い合うことができるiOSアプリです。Firebaseをバックエンドとして使用し、リアルタイムでの学習データ同期とユーザー間でのランキング機能を提供します。

## 機能

### 🎯 主要機能
- **学習タイマー**: 集中時間を測定・記録
- **全国ランキング**: 他のユーザーと学習時間を競争
- **学習記録**: 日別・期間別の学習統計
- **タイムライン**: 学習活動の履歴表示
- **報酬システム**: 学習達成に応じたバッジやレベルアップ
- **プロフィール管理**: ユーザー情報とアバターのカスタマイズ

### 📱 インターフェース
- **ダークテーマ**: 目に優しいミニマルなデザイン
- **タブベース**: 直感的なナビゲーション
- **リアルタイム更新**: Firebase経由での即座な同期
- **バックグラウンド対応**: アプリを閉じても学習時間を追跡

## 技術スタック

### フレームワーク
- **SwiftUI**: モダンなUIフレームワーク
- **Combine**: リアクティブプログラミング
- **Firebase**: バックエンドサービス
  - Firebase Auth: ユーザー認証
  - Firestore: NoSQLデータベース
  - Firebase App Check: セキュリティ
- **UserNotifications**: プッシュ通知

### アーキテクチャ
- **MVVM**: Model-View-ViewModelパターン
- **@StateObject/@ObservableObject**: SwiftUIの状態管理
- **@MainActor**: メインスレッドでの安全な更新
- **Swift Concurrency**: async/awaitによる非同期処理

## プロジェクト構成

```
StudyArena/
├── StudyArena.swift           # メインアプリエントリーポイント
├── ContentView.swift          # ルートビュー
├── MainTabView.swift          # タブベースのメインビュー
├── MainViewModel.swift        # メインのビジネスロジック
├── Views/
│   ├── TimerView.swift       # 学習タイマー画面
│   ├── RankingView.swift     # ランキング表示
│   ├── ProfileView.swift     # プロフィール管理
│   ├── RewardSystemView.swift # 報酬システム
│   ├── PostCreateView.swift  # 投稿作成
│   └── UserStatusCard.swift  # ユーザーステータス表示
├── Components/
│   ├── BackgroundTracker.swift    # バックグラウンド追跡
│   ├── NotificationManager.swift  # 通知管理
│   ├── FeedbackView.swift         # フィードバック
│   └── SideNavigationView.swift   # サイドメニュー
└── Utils/
    └── Constants.swift        # 定数定義
```

## セットアップ

### 前提条件
- Xcode 15.0以上
- iOS 17.0以上
- Firebase プロジェクト

### インストール手順

1. **リポジトリのクローン**
   ```bash
   git clone [repository-url]
   cd StudyArena
   ```

2. **Firebase設定**
   - [Firebase Console](https://console.firebase.google.com/)でプロジェクトを作成
   - `GoogleService-Info.plist`をダウンロードしてプロジェクトに追加
   - Firestore、Firebase Authを有効化

3. **Xcode設定**
   - `StudyArena.xcodeproj`をXcodeで開く
   - Bundle Identifierを設定
   - Signing & Capabilitiesを設定

4. **ビルドと実行**
   ```bash
   # シミュレーター
   cmd + R でビルド・実行
   
   # 実機デバイス
   開発者アカウントでコード署名後に実行
   ```

## Firebase設定

### Firestoreデータベース構造
```
users/
  ├── {userId}/
  │   ├── nickname: String
  │   ├── totalStudyTime: Number
  │   ├── level: Number
  │   ├── avatarUrl: String
  │   └── createdAt: Timestamp

studyRecords/
  ├── {recordId}/
  │   ├── userId: String
  │   ├── duration: Number
  │   ├── startTime: Timestamp
  │   └── endTime: Timestamp

departments/
  ├── {departmentId}/
  │   ├── name: String
  │   ├── memberCount: Number
  │   └── createdAt: Timestamp
```

### セキュリティルール例
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のデータのみ読み書き可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 学習記録は認証済みユーザーのみ
    match /studyRecords/{recordId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 開発

### デバッグ
- プレビューモード対応済み（モックデータ使用）
- Firebaseエミュレーター対応
- 詳細なログ出力

### 新機能追加
1. `MainViewModel.swift`にビジネスロジックを追加
2. 対応するSwiftUIビューを作成
3. `MainTabView.swift`にナビゲーションを追加

### テスト
```swift
// Swift Testingフレームワークを使用
import Testing

@Suite("StudyArena Tests")
struct StudyArenaTests {
    
    @Test("Timer calculation")
    func timerCalculation() async throws {
        let viewModel = MainViewModel()
        // テストコード
    }
}
```

## 貢献

1. Forkを作成
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. Pull Requestを作成

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## サポート

問題や質問がある場合は、[Issues](../../issues)にて報告してください。

---

**開発者**: StudyArena Team  
**最終更新**: 2024年11月