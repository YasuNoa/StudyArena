import SwiftUI

struct DepartmentBrowserView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingCreateDepartment = false
    @State private var searchText = ""
    @State private var selectedCategory: DepartmentCategory? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // 検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("部門を検索...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // カテゴリフィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryChip(
                            category: .technology,
                            isSelected: selectedCategory == .technology
                        ) {
                            selectedCategory = selectedCategory == .technology ? nil : .technology
                        }
                        
                        CategoryChip(
                            category: .language,
                            isSelected: selectedCategory == .language
                        ) {
                            selectedCategory = selectedCategory == .language ? nil : .language
                        }
                        
                        CategoryChip(
                            category: .business,
                            isSelected: selectedCategory == .business
                        ) {
                            selectedCategory = selectedCategory == .business ? nil : .business
                        }
                        
                        CategoryChip(
                            category: .science,
                            isSelected: selectedCategory == .science
                        ) {
                            selectedCategory = selectedCategory == .science ? nil : .science
                        }
                        
                        CategoryChip(
                            category: .art,
                            isSelected: selectedCategory == .art
                        ) {
                            selectedCategory = selectedCategory == .art ? nil : .art
                        }
                        
                        CategoryChip(
                            category: .health,
                            isSelected: selectedCategory == .health
                        ) {
                            selectedCategory = selectedCategory == .health ? nil : .health
                        }
                        
                        CategoryChip(
                            category: .other,
                            isSelected: selectedCategory == .other
                        ) {
                            selectedCategory = selectedCategory == .other ? nil : .other
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // 部門一覧
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredDepartments) { department in
                            DepartmentCard(
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
                }
            }
            .navigationTitle("部門を探す")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.canCreateDepartment {
                        Button(action: {
                            showingCreateDepartment = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateDepartment) {
            CreateDepartmentView(viewModel: viewModel)
        }
        .task {
            await viewModel.fetchDepartments()
            await viewModel.fetchUserMemberships()
            viewModel.checkDepartmentCreationPermission()
        }
    }
    
    private var filteredDepartments: [Department] {
        var filtered = viewModel.departments
        
        // 検索テキストでフィルター
        if !searchText.isEmpty {
            filtered = filtered.filter { department in
                department.name.localizedCaseInsensitiveContains(searchText) ||
                department.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // カテゴリでフィルター
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { department in
                department.category == selectedCategory
            }
        }
        
        return filtered
    }
}

struct DepartmentCard: View {
    let department: Department
    let isJoined: Bool
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー
            HStack {
                // アイコン
                Image(systemName: department.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: department.color) ?? .blue)
                
                VStack(alignment: .leading) {
                    Text(department.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("作成者: \(department.creatorName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(department.memberCount)人")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(formatDate(department.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 説明
            Text(department.description)
                .font(.body)
                .lineLimit(3)
            
            // タグ
            if !department.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(department.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                }
            }
            
            // 参加ボタン
            HStack {
                Spacer()
                
                if isJoined {
                    Text("参加済み")
                        .font(.caption)
                        .foregroundColor(.green)
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct CreateDepartmentView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var departmentName = ""
    @State private var departmentDescription = ""
    @State private var selectedCategory: DepartmentCategory = .other
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("部門情報") {
                    TextField("部門名", text: $departmentName)
                    
                    TextField("部門の説明", text: $departmentDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(DepartmentCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("部門を作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createDepartment()
                    }
                    .disabled(departmentName.isEmpty || departmentDescription.isEmpty || isCreating)
                }
            }
        }
    }
    
    private func createDepartment() {
        isCreating = true
        
        Task {
            do {
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

// MARK: - Color Extension (既存の拡張)
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
