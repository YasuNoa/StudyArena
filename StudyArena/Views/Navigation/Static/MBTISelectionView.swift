//
//  MBTISelectionView.swift
//  StudyArena
//
//  Created by 田中正造 on 22/08/2025.
//


import SwiftUI

struct MBTISelectionView: View {
    @Binding var selectedMBTI: String?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MainViewModel
    @State private var isSaving = false
    
    let mbtiTypes = [
        ["INTJ", "INTP", "ENTJ", "ENTP"],
        ["INFJ", "INFP", "ENFJ", "ENFP"],
        ["ISTJ", "ISFJ", "ESTJ", "ESFJ"],
        ["ISTP", "ISFP", "ESTP", "ESFP"]
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("あなたのMBTIタイプを選択")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        // MBTIグリッド
                        VStack(spacing: 15) {
                            ForEach(mbtiTypes, id: \.self) { row in
                                HStack(spacing: 15) {
                                    ForEach(row, id: \.self) { type in
                                        MBTITypeCard(
                                            type: type,
                                            isSelected: selectedMBTI == type,
                                            action: {
                                                selectedMBTI = type
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 保存ボタン
                        if selectedMBTI != nil {
                            Button(action: saveMBTIType) {
                                Text("保存する")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("MBTIタイプ選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func saveMBTIType() {
        guard let mbti = selectedMBTI else { return }
        
        isSaving = true  // ← 保存中フラグを追加
        
        Task {
            do {
                // ユーザー情報を更新
                guard var user = viewModel.user else { return }
                user.mbtiType = mbti
                viewModel.user = user  // ← ViewModelのuserを更新
                
                // Firestoreに保存
                try await viewModel.saveUserData(userToSave: user)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("MBTI保存エラー: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MBTIタイプカード
struct MBTITypeCard: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isSelected ? .white : .purple)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.purple : Color.purple.opacity(0.1))
                )
        }
    }
}
