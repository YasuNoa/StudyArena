import SwiftUI

struct DepartmentBrowserView: View {
    @ObservedObject var viewModel: MainViewModel
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
                        
                        TextField("部門を検索...", text: $searchText)
                            .textFieldStyle(DarkTextFieldStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // 部門一覧
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredDepartments) { department in
                                DepartmentBrowserCard(
                                    department: department,
                                    isJoined: viewModel.isJoinedDepartment(department.id ?? ""),
                                    onJoin: {
                                        Task {
                                            do {
                                                try await viewModel.joinDepartment(department)
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
                    }
                }
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
                    if (viewModel.user?.level ?? 0) >= 10 {
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
            CreateDepartmentView(viewModel: viewModel)
        }
        .task {
            // 🔧 修正: 既存のメソッド名を使用
            await viewModel.loadDepartments()
            await viewModel.fetchUserMemberships()
        }
    }
    
    private var filteredDepartments: [Department] {
        if searchText.isEmpty {
            return viewModel.departments
        } else {
            return viewModel.departments.filter { department in
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
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var departmentName = ""
    @State private var departmentDescription = ""
    @State private var isCreating = false
    
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
        }
    }
    
    private func createDepartment() {
        isCreating = true
        
        Task {
            do {
                // 🔧 修正: 既存のメソッドを使用
                try await viewModel.createDepartment(
                    name: departmentName,
                    description: departmentDescription
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("部門作成エラー: \(error)")
            }
            
            await MainActor.run {
                isCreating = false
            }
        }
    }
}
