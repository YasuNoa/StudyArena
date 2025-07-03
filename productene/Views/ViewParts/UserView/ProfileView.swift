//
//  ProfileView.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var nickname: String = ""
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
                            TextField("ニックネーム", text: $nickname)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        } else {
                            Text(nickname.isEmpty ? "未設定" : nickname)
                                .foregroundColor(nickname.isEmpty ? .secondary : .primary)
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
                        
                        HStack {
                            Text("解放済み偉人数")
                            Spacer()
                            Text("\(user.unlockedPersonIDs.count)人")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section {
                    if isEditing {
                        HStack {
                            Button("キャンセル") {
                                nickname = viewModel.user?.nickname ?? ""
                                isEditing = false
                            }
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("保存") {
                                saveProfile()
                            }
                            .fontWeight(.semibold)
                            .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button("プロフィールを編集") {
                            isEditing = true
                        }
                    }
                }
            }
            .navigationTitle("プロフィール")
            .onAppear {
                nickname = viewModel.user?.nickname ?? ""
            }
            .alert("保存しました", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private func saveProfile() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { return }
        
        viewModel.user?.nickname = trimmedNickname
        
        Task {
            do {
                try await viewModel.saveUserData()
                await MainActor.run {
                    isEditing = false
                    showSaveAlert = true
                }
            } catch {
                print("プロフィール保存エラー: \(error)")
            }
        }
    }
}
