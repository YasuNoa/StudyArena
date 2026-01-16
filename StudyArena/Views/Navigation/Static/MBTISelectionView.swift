
import SwiftUI

struct MBTISelectionView: View {
    @Binding var selectedMBTI: String?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MainViewModel
    @State private var isSaving = false
    @State private var tempSelectedMBTI: String? = nil
    @State private var errorMessage: String? = nil
    
    // 既存のallMBTITypesと同じ配列構造を使用
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
                        // ヘッダー
                        VStack(spacing: 8) {
                            Text("MBTIタイプを選択")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("あなたの性格タイプを選んでください")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top)
                        
                        // MBTIグリッド（既存のレイアウトを改良）
                        VStack(spacing: 15) {
                            ForEach(mbtiTypes, id: \.self) { row in
                                HStack(spacing: 12) {
                                    ForEach(row, id: \.self) { type in
                                        EnhancedMBTITypeCard(
                                            type: type,
                                            isSelected: tempSelectedMBTI == type,
                                            action: {
                                                tempSelectedMBTI = type
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 未設定オプション
                        Button(action: {
                            tempSelectedMBTI = nil
                        }) {
                            HStack {
                                Image(systemName: tempSelectedMBTI == nil ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(tempSelectedMBTI == nil ? .blue : .gray)
                                Text("未設定にする")
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(tempSelectedMBTI == nil ? Color.blue.opacity(0.1) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(tempSelectedMBTI == nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal)
                        
                        // エラーメッセージ
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // 保存ボタン（変更がある場合のみ表示）
                        if tempSelectedMBTI != selectedMBTI {
                            Button(action: saveMBTIType) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(isSaving ? "保存中..." : "保存する")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .shadow(color: .purple.opacity(0.3), radius: 5)
                            }
                            .disabled(isSaving)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("MBTI選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                // 初期値を現在のMBTIに設定
                tempSelectedMBTI = selectedMBTI
            }
        }
    }
    
    private func saveMBTIType() {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // 新しい統合メソッドを使用 (MBTIViewModel経由)
                // MainViewModelにはUser更新の責任だけ残し、ロジックはMBTIViewModelへという形だが、
                // User更新はUserServiceの責務で、MBTIViewModelがUserServiceを使う形にしたため、
                // ここではMBTIViewModelのメソッドを呼ぶ。
                // ただし、MainViewModelの再読込が必要。
                
                let mbtiVM = MBTIViewModel()
                if let userId = viewModel.user?.id {
                     try await mbtiVM.updateMBTIType(userId: userId, type: tempSelectedMBTI)
                     // MainViewModelのデータを更新して画面反映
                     await viewModel.loadUserData(uid: userId)
                }
                
                await MainActor.run {
                    selectedMBTI = tempSelectedMBTI
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "保存に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

// 3. 強化されたMBTIカード

struct EnhancedMBTITypeCard: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(type)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : .purple)
                
                let info = MBTIViewModel.getMBTIInfo(type)
                Text(info.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .purple.opacity(0.8))
                
                Text(info.description)
                    .font(.system(size: 8))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 85)
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.purple : Color.purple.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? Color.purple : Color.purple.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
    }
}
