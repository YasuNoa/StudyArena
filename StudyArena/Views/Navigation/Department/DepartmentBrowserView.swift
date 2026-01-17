// 部門を検索・一覧表示し、新規作成や参加を行うためのビュー
//部門を検索するためのview
//部門一覧がDepartment型？にしてたから、型の不一致に注意

import SwiftUI

struct DepartmentBrowserView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var departmentViewModel = DepartmentViewModel()
    @State private var showingCreateDepartment = false
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                
                VStack(spacing: 0) {
                    // 検索バー
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        //部門検索ビュー
                        TextField("部門を検索...", text: $searchText)
                            .textFieldStyle(DarkTextFieldStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 10) // 少し余白追加
                    
                    if departmentViewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Spacer()
                    } else {
                        // 部門一覧
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredDepartments) { department in
                                    DepartmentBrowserCard(
                                        department: department,
                                        isJoined: departmentViewModel.isJoinedDepartment(department.id ?? ""),
                                        onJoin: {
                                            Task {
                                                do {
                                                    try await departmentViewModel.joinDepartment(department)
                                                } catch {
                                                    print("部門参加エラー: \(error)")
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            .padding(.bottom, 30) // 下部にも余白
                        }
                    }
                }
                .padding(.horizontal, 8) // 全体に少し横余白を追加してフルスクリーン時の圧迫感を軽減
            }
            .navigationTitle("部門を探す")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 🔧 修正: canCreateDepartmentプロパティが存在しない場合のチェック
                    //ここ、本番では10にしてレベル制限をかける。
                    if (viewModel.user?.level ?? 0) >= 1 {
                        Button(action: {
                            showingCreateDepartment = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateDepartment) {
            CreateDepartmentView(departmentViewModel: departmentViewModel)
        }
        .task {
            // MainViewModelからユーザー情報を同期
            departmentViewModel.userId = viewModel.user?.id
            departmentViewModel.user = viewModel.user
            
            await departmentViewModel.loadDepartments()
            await departmentViewModel.loadUserMemberships()
        }
    }
    
    private var filteredDepartments: [Department] {
        if searchText.isEmpty {
            return departmentViewModel.departments
        } else {
            return departmentViewModel.departments.filter { department in
                department.name.localizedCaseInsensitiveContains(searchText) ||
                department.description.localizedCaseInsensitiveContains(searchText) ||
                department.creatorName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// 🔧 新しい名前の部門カード（重複回避）
struct DepartmentBrowserCard: View {
    let department: Department
    let isJoined: Bool
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(department.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("作成者: \(department.creatorName)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(department.memberCount)人")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(formatDate(department.createdAt))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // 説明
            Text(department.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
            
            // 参加ボタン
            HStack {
                Spacer()
                
                if isJoined {
                    Text("参加済み")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.2))
                        )
                } else {
                    Button("参加する", action: onJoin)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// 🔧 シンプルな部門作成ビュー
struct CreateDepartmentView: View {
    @ObservedObject var departmentViewModel: DepartmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var departmentName = ""
    @State private var departmentDescription = ""
    @State private var isCreating = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                
                VStack(spacing: 20) {
                    Text("新しい部門を作成")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(spacing: 16) {
                        TextField("部門名", text: $departmentName)
                            .textFieldStyle(DarkTextFieldStyle())
                        
                        TextField("部門の説明", text: $departmentDescription, axis: .vertical)
                            .textFieldStyle(DarkTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.horizontal, 8) // こちらも横に少し余白
            }
            .navigationTitle("部門作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createDepartment()
                    }
                    .foregroundColor(.blue)
                    .disabled(departmentName.isEmpty || departmentDescription.isEmpty || isCreating)
                }
            }
            .disabled(isCreating) // 作成中は全体を無効化
            .overlay {
                if isCreating {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                }
            }
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createDepartment() {
        isCreating = true
        
        Task {
            do {
                // 🔧 修正: 既存のメソッドを使用
                try await departmentViewModel.createDepartment(
                    name: departmentName,
                    description: departmentDescription
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("部門作成エラー: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    // もしNSErrorで詳細なメッセージが取れない場合はこちらを検討:
                    // errorMessage = (error as NSError).domain == "DepartmentError" ? "部門作成に失敗しました: \(error.localizedDescription)" : "不明なエラーが発生しました"
                    if let nsError = error as NSError?, nsError.domain == "DepartmentError", nsError.code == 10 {
                         errorMessage = "レベル10以上のユーザーのみ部門を作成できます"
                    }
                    showingErrorAlert = true
                }
            }
            
            await MainActor.run {
                isCreating = false
            }
        }
    }
}
