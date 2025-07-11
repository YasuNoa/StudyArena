import SwiftUI

struct TimerButton: View {
    let isRunning: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            // ボタンの見た目（アイコンとテキスト）
            HStack(spacing: 15) {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .font(.title)
                Text(isRunning ? "STOP" : "START")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
            .frame(minWidth: 200) // 最小幅を設定してサイズを安定させる
        }
        .background(.ultraThinMaterial) // 半透明の「すりガラス」背景
        .clipShape(Capsule()) // 角を丸めてカプセル状にする
        .foregroundColor(
            // isRunningの状態によって文字色とアイコンの色を変化させる
            isRunning ? .accentColor : .white // STOP時は白、START時はアプリのテーマカラー（青）
        )
        .overlay( // 縁取り
            Capsule()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(0.2), // 影を黒系の薄い色に変更
            radius: 10,
            x: 0,
            y: 5
        )
        .animation(.easeInOut(duration: 0.2), value: isRunning) // 色の変化にアニメーションを適用
    }
}
