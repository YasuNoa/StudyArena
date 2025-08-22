import SwiftUI

struct PostCreateView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: MainViewModel
    
    @State private var postContent = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPosting = false
    
    // ⭐️ レベルに応じた文字数制限を計算（新計算式版）
    var postLimit: Int {
        guard let user = viewModel.user else { return 5 }
        return user.postCharacterLimit
    }
    
    // 入力制限は投稿制限の3倍程度に設定
    var inputLimit: Int { postLimit * 3 }
    
    var characterCount: Int { postContent.count }
    var remainingCharacters: Int { postLimit - characterCount }
    var canPost: Bool { characterCount >= 1 && characterCount <= postLimit && !isPosting }
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            // メインコンテンツ
            VStack(spacing: 0) {
                // ヘッダー
                PostCreateHeader(
                    isPresented: $isPresented,
                    canPost: canPost,
                    onPost: postToTimeline
                )
                
                // 投稿エリア
                VStack(alignment: .leading, spacing: 20) {
                    // ユーザー情報
                    PostUserInfo(user: viewModel.user, postLimit: postLimit)
                    
                    // テキスト入力
                    PostTextEditor(
                        text: $postContent,
                        inputLimit: inputLimit
                    )
                    
                    // 文字数表示
                    PostCharacterCounter(
                        characterCount: characterCount,
                        postLimit: postLimit,
                        remainingCharacters: remainingCharacters
                    )
                    
                    // ⭐️ レベルと文字数制限の情報
                    PostLevelInfoBanner(
                        currentLevel: viewModel.user?.level ?? 1,
                        postLimit: postLimit
                    )
                }
                .padding()
                
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                    .ignoresSafeArea()
            )
            .offset(y: 50)
        }
        .alert("投稿エラー", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func postToTimeline() {
        // ⭐️ 重複投稿防止のため、すでに投稿中なら何もしない
        guard canPost, !isPosting else { return }
        
        isPosting = true
        
        Task {
            do {
                // ⭐️ 投稿前に必ず今日の投稿状況をチェック
                let hasPostedToday = await viewModel.hasPostedToday()
                print("📝 今日の投稿状況: \(hasPostedToday)") 
                
                if hasPostedToday {
                    await MainActor.run {
                        alertMessage = "今日はすでに投稿済みです。明日また投稿してください。"
                        showAlert = true
                        isPosting = false
                    }
                    return
                }
                
                // 投稿を実行
                try await viewModel.createTimelinePost(content: postContent)
                
                // ⭐️ 成功時は画面を閉じる前に少し待機（重複タップ防止）
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
                
                await MainActor.run {
                    isPresented = false
                    isPosting = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "投稿に失敗しました: \(error.localizedDescription)"
                    showAlert = true
                    isPosting = false
                }
            }
        }
    }
}

// ヘッダーコンポーネント
struct PostCreateHeader: View {
    @Binding var isPresented: Bool
    let canPost: Bool
    let onPost: () -> Void
    
    var body: some View {
        HStack {
            Button("キャンセル") {
                isPresented = false
            }
            .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text("今日の一言")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("投稿", action: onPost)
                .font(.headline)
                .foregroundColor(canPost ? .cyan : .white.opacity(0.3))
                .disabled(!canPost)
                .allowsHitTesting(canPost) // ⭐️ タップを物理的に無効化
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    }
}

// ユーザー情報コンポーネント
struct PostUserInfo: View {
    let user: User?
    let postLimit: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user?.nickname.prefix(1) ?? "?"))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user?.nickname ?? "名無し")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Text("Lv.\(user?.level ?? 1)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    // ⭐️ 文字数制限の表示を追加
                    Text("・")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("最大\(postLimit)文字")
                        .font(.caption)
                        .foregroundColor(.cyan.opacity(0.8))
                }
            }
            
            Spacer()
        }
    }
}

// テキストエディターコンポーネント
struct PostTextEditor: View {
    @Binding var text: String
    let inputLimit: Int
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("今日の学習について一言")
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }
            
            TextEditor(text: $text)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .font(.system(size: 18))
                .frame(minHeight: 100, maxHeight: 200)
                .onChange(of: text) { _, newValue in
                    if newValue.count > inputLimit {
                        text = String(newValue.prefix(inputLimit))
                    }
                }
        }
    }
}

// 文字数カウンターコンポーネント
struct PostCharacterCounter: View {
    let characterCount: Int
    let postLimit: Int
    let remainingCharacters: Int
    
    var body: some View {
        HStack {
            if characterCount == 0 {
                Text("何か入力してください")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if characterCount > postLimit {
                Text("\(abs(remainingCharacters))文字オーバー")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            // X風の文字数表示
            CharacterProgressCircle(
                characterCount: characterCount,
                postLimit: postLimit,
                remainingCharacters: remainingCharacters
            )
        }
    }
}

// プログレスサークル
struct CharacterProgressCircle: View {
    let characterCount: Int
    let postLimit: Int
    let remainingCharacters: Int
    
    var progress: CGFloat {
        min(1.0, CGFloat(characterCount) / CGFloat(postLimit))
    }
    
    var color: Color {
        if characterCount > postLimit { return .red }
        if characterCount > postLimit * 8 / 10 { return .orange }
        return .green
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 3)
                .frame(width: 30, height: 30)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, lineWidth: 3)
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: characterCount)
            
            if characterCount > postLimit * 8 / 10 || characterCount > postLimit {
                Text("\(remainingCharacters)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
        }
        .padding(.trailing, 5)
    }
}

// ⭐️ レベル情報バナー（非線形文字数増加対応版）
struct PostLevelInfoBanner: View {
    let currentLevel: Int
    let postLimit: Int
    
    // 次の文字数増加を計算（動的版）
    var nextCharacterIncrease: (level: Int, chars: Int)? {
        // 現在の文字数
        let currentChars = postLimit
        
        // レベルを少しずつ上げて、文字数が増える地点を探す
        for checkLevel in (currentLevel + 1)...(currentLevel + 1000) {
            var tempUser = User(level: checkLevel)
            let nextChars = tempUser.postCharacterLimit
            
            if nextChars > currentChars {
                return (level: checkLevel, chars: nextChars)
            }
            
            // 最大値に達した場合
            if nextChars >= 500 {
                return nil
            }
        }
        
        return nil
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // 現在の文字数制限
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.7))
                
                Text("1日1回、\(postLimit)文字以内で投稿")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // 次のマイルストーン表示
            if let next = nextCharacterIncrease {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow.opacity(0.8))
                    
                    Text("Lv.\(next.level)で\(next.chars)文字投稿可能")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow.opacity(0.7))
                }
            } else if postLimit >= 500 {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)
                    
                    Text("最大文字数（500文字）に到達！")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.black
        
        PostCreateView(isPresented: .constant(true))
            .environmentObject(MainViewModel.mock)
    }
}
#endif
