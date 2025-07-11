import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var editingNickname: String = ""
    @State private var showSaveAlert: Bool = false
    @State private var isEditing: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("プロフィール設定")) {
                    HStack {
                        Text("ニックネーム")
                        Spacer()
                        if isEditing {
                            TextField("新しいニックネームを入力", text: $editingNickname)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        } else {
                            let displayName = viewModel.user?.nickname ?? ""
                            Text(displayName.isEmpty ? "未設定" : displayName)
                                .foregroundColor(displayName.isEmpty ? .secondary : .primary)
                        }
                    }
                }
                
                if let user = viewModel.user {
                    Section(header: Text("統計情報")) {
                        HStack {
                            Text("レベル")
                            Spacer()
                            Text("Lv. \(user.level)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("総学習時間")
                            Spacer()
                            Text(viewModel.formatTime(user.totalStudyTime))
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section {
                    if isEditing {
                        HStack(spacing: 20) {
                            Button("キャンセル") {
                                isEditing = false
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("保存") {
                                saveProfile()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(editingNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button("プロフィールを編集") {
                            editingNickname = viewModel.user?.nickname ?? ""
                            isEditing = true
                        }
                    }
                }
            }
            .navigationTitle("プロフィール")
            .alert("保存しました", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private func saveProfile() {
        let trimmedNickname = editingNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { return }
        
        guard var updatedUser = viewModel.user else { return }
        updatedUser.nickname = trimmedNickname
        
        viewModel.user = updatedUser
        
        Task {
            do {
                try await viewModel.saveUserData(userToSave: updatedUser)
                
                await MainActor.run {
                    isEditing = false
                    showSaveAlert = true
                }
                
                viewModel.loadRanking()
            } catch {
                // 保存失敗時のエラーハンドリング（例: アラート表示）
                print("プロフィールの保存に失敗しました: \(error)")
            }
        }
    }
}

#Preview {
    let mockViewModel = MainViewModel()
    mockViewModel.user = User(nickname: "プレビュー太郎", level: 10)
    mockViewModel.isLoading = false
    
    return ProfileView()
        .environmentObject(mockViewModel)
}
