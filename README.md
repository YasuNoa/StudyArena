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
**Modular MVVM (Model-View-ViewModel + Services + Managers)**

- **Views (UI)**: SwiftUIによる画面描画。`ViewModel`の状態を監視・反映します。
- **ViewModels (Binding & Logic)**: ViewとModel/Serviceの仲介役。
    - UIの状態管理 (`@Published`)
    - Combineを使用したデータのバインディング
    - `Manager`や`Service`への処理委譲
- **Managers (System & State)**: アプリ全体の状態やシステム機能を管理。
    - `AuthManager`: 認証状態の監視
    - `TimerManager`: バックグラウンド対応のタイマー制御
    - `NotificationManager`: ローカル通知の管理
- **Services (Data Access)**: バックエンド（Firebase）との通信を担当。
    - `UserService`: ユーザー情報のCRUD
    - `StudyRecordService`: 学習記録の保存
    - `TimelineService`: タイムラインデータの取得・更新

### ディレクトリ構成
```text
StudyArena/
  ├── StudyArena.swift         # アプリのエントリーポイント（App Check設定含む）
  ├── Managers/                # アプリ全体の機能管理 (Auth, Timer, Notification)
  ├── Services/                # データアクセス層 (Firebase Firestore)
  ├── ViewModels/              # 画面ごとのビジネスロジック
  ├── Views/                   # SwiftUI View
  │   ├── Navigation/          # ナビゲーション関連
  │   └── ViewParts/           # 再利用可能なUIコンポーネント
  ├── Model/                   # データモデル定義
  └── Assets.xcassets/         # 画像リソース
```

### Firestore Data Structure

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

##
https://apps.apple.com/jp/app/studyarena/id6748235227?l=en-US

問題や質問がある場合は、[Issues](../../issues)にて報告してください。

---
開発者:Yasu
