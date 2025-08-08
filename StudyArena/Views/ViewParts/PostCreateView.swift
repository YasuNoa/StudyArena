import SwiftUI

struct PostCreateView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: MainViewModel
    
    @State private var postContent = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPosting = false
    
    // 文字数制限
    private let postLimit = 10
    private let inputLimit = 31
    
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
                    PostUserInfo(user: viewModel.user)
                    
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
                    
                    // 注意事項
                    PostInfoBanner()
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
        guard canPost else { return }
        
        isPosting = true
        
        Task {
            do {
                let hasPostedToday = await viewModel.hasPostedToday()
                
                if hasPostedToday {
                    alertMessage = "今日はすでに投稿済みです。明日また投稿してください。"
                    showAlert = true
                    isPosting = false
                    return
                }
                
                try await viewModel.createTimelinePost(content: postContent)
                isPresented = false
            } catch {
                alertMessage = "投稿に失敗しました: \(error.localizedDescription)"
                showAlert = true
                isPosting = false
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
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    }
}

// ユーザー情報コンポーネント
struct PostUserInfo: View {
    let user: User?
    
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
                
                Text("Lv.\(user?.level ?? 1)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
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
            
            if characterCount > postLimit * 8 / 10 {
                Text("\(remainingCharacters)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
        }
        .padding(.trailing, 5)
    }
}

// 情報バナー
struct PostInfoBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .font(.caption)
                .foregroundColor(.blue.opacity(0.7))
            
            Text("1日1回、10文字以内で投稿")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
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
