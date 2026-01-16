import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MainViewModel
    
    @StateObject private var feedbackViewModel = FeedbackViewModel()
    
    @State private var feedbackType = "機能要望"
    @State private var feedbackText = ""
    @State private var email = ""
    
    let feedbackTypes = ["バグ報告", "機能要望", "改善提案", "その他"]
    
    // 文字数制限
    private let maxContentLength = 100
    private let maxEmailLength = 100
    
    var canSubmit: Bool {
        !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        feedbackText.count <= maxContentLength &&
        isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) &&
        !feedbackViewModel.isSubmitting &&
        !feedbackViewModel.hasSubmittedToday
    }
    
    // メールアドレスの形式チェック
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email) && !email.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                
                if feedbackViewModel.isCheckingLimit {
                    // 制限チェック中の表示
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("チェック中...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                } else if feedbackViewModel.hasSubmittedToday {
                    // 1日1回制限に達している場合
                    VStack(spacing: 30) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        VStack(spacing: 15) {
                            Text("本日の送信完了")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("フィードバックは1日1回までです。\n明日以降に再度お試しください。")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        
                        Button("閉じる") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding()
                } else {
                    // 通常のフィードバック入力画面
                    ScrollView {
                        VStack(spacing: 25) {
                            // ヘッダー情報
                            VStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                
                                Text("フィードバック")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("ご意見・ご要望をお聞かせください")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                // 1日1回の注意書き（日本時間）
                                Text("※ フィードバックは1日1回まで送信できます（日本時間0時リセット）")
                                    .font(.caption)
                                    .foregroundColor(.orange.opacity(0.8))
                            }
                            .padding(.top)
                            
                            VStack(spacing: 20) {
                                // フィードバックタイプ選択
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("フィードバックの種類")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Picker("種類", selection: $feedbackType) {
                                        ForEach(feedbackTypes, id: \.self) { type in
                                            Text(type).tag(type)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .colorScheme(.dark)
                                }
                                
                                // フィードバック内容
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("内容")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(feedbackText.count)/\(maxContentLength)")
                                            .font(.caption)
                                            .foregroundColor(
                                                feedbackText.count > maxContentLength ? .red :
                                                    feedbackText.count > maxContentLength * 8 / 10 ? .orange : .white.opacity(0.5)
                                            )
                                    }
                                    
                                    ZStack(alignment: .topLeading) {
                                        if feedbackText.isEmpty {
                                            Text("具体的な内容をお書きください（100文字以内）\n\n例：\n・バグ: タイマーが止まらない\n・要望: 通知機能が欲しい\n・改善: ボタンが小さい")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.3))
                                                .padding(.top, 8)
                                                .padding(.leading, 4)
                                        }
                                        
                                        TextEditor(text: $feedbackText)
                                            .frame(minHeight: 120)
                                            .scrollContentBackground(.hidden)
                                            .background(Color.clear)
                                            .foregroundColor(.white)
                                            .font(.subheadline)
                                            .onChange(of: feedbackText) { _, newValue in
                                                if newValue.count > maxContentLength {
                                                    feedbackText = String(newValue.prefix(maxContentLength))
                                                }
                                            }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(
                                                        feedbackText.count > maxContentLength ? Color.red :
                                                            Color.white.opacity(0.3),
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                }
                                
                                // メールアドレス（必須）
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("メールアドレス")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text("（必須）")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    
                                    TextField("your@example.com", text: $email)
                                        .textFieldStyle(DarkTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .onChange(of: email) { _, newValue in
                                            if newValue.count > maxEmailLength {
                                                email = String(newValue.prefix(maxEmailLength))
                                            }
                                        }
                                    
                                    // メールアドレスのバリデーションエラー表示
                                    if !email.isEmpty && !isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                        Text("正しいメールアドレスを入力してください")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            // 送信ボタン
                            VStack(spacing: 10) {
                                // 送信不可の理由を表示
                                if !canSubmit && !feedbackViewModel.isSubmitting {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            Text("• 内容を入力してください")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        if feedbackText.count > maxContentLength {
                                            Text("• 内容は100文字以内で入力してください")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                        if !isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                            Text("• 正しいメールアドレスを入力してください")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                }
                                
                                Button(action: submitFeedback) {
                                    HStack {
                                        if feedbackViewModel.isSubmitting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        }
                                        
                                        Text(feedbackViewModel.isSubmitting ? "送信中..." : "送信")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: canSubmit ? [.blue, .cyan] : [.gray, .gray.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .opacity(canSubmit ? 1.0 : 0.6)
                                }
                                .disabled(!canSubmit)
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("フィードバック")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            checkDailyLimit()
        }
        .alert("送信完了", isPresented: $feedbackViewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("フィードバックを送信しました。ご協力ありがとうございます！")
        }
        .alert("送信エラー", isPresented: $feedbackViewModel.showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(feedbackViewModel.errorMessage ?? "")
        }
    }
    
    // 修正: checkDailyLimit関数を実装
    private func checkDailyLimit() {
        guard let userId = viewModel.user?.id else { return }
        Task {
            await feedbackViewModel.checkDailyLimit(userId: userId)
        }
    }
    
    private func submitFeedback() {
        guard !feedbackViewModel.isSubmitting else { return }
        guard let user = viewModel.user else { return }
        
        Task {
            do {
                try await feedbackViewModel.submitFeedback(
                    userId: user.id,
                    userNickname: user.nickname,
                    userLevel: user.level,
                    type: feedbackType,
                    content: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            } catch {
            }
        }
    }
}
