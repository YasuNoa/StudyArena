//
//  SideNavigationView.swift
//  StudyArena
//
//  Created by 田中正造 on 17/08/2025.
//


// StudyArena/Views/Navigation/SideNavigationView.swift

import SwiftUI

// MARK: - メインのサイドナビゲーション
struct SideNavigationView: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: MainTabView.Tab
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingSection: NavigationSection? = nil
    @State private var showFeedback = false
    @State private var showDepartmentJoin = false
    
    enum NavigationSection: String, CaseIterable {
        case main = "メイン"
        case department = "部門"
        case stats = "統計・記録"
        case settings = "設定"
        case support = "サポート"
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 背景（タップで閉じる）
            Color.black.opacity(isShowing ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }
            
            // サイドメニュー本体
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    // ヘッダー：ユーザー情報
                    UserHeaderView()
                        .padding()
                        .background(Color.white.opacity(0.05))
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // メインナビゲーション
                            MenuSection(title: "メイン") {
                                NavigationItem(
                                    icon: "timer",
                                    title: "タイマー",
                                    color: .blue
                                ) {
                                    selectedTab = .timer
                                    isShowing = false
                                }
                                
                                NavigationItem(
                                    icon: "crown.fill",
                                    title: "ランキング",
                                    color: .orange
                                ) {
                                    selectedTab = .ranking
                                    isShowing = false
                                }
                                
                                NavigationItem(
                                    icon: "clock.arrow.circlepath",
                                    title: "タイムライン",
                                    color: .green
                                ) {
                                    selectedTab = .timeline
                                    isShowing = false
                                }
                                
                                NavigationItem(
                                    icon: "person.fill",
                                    title: "プロフィール",
                                    color: .purple
                                ) {
                                    selectedTab = .profile
                                    isShowing = false
                                }
                            }
                            
                            // 部門関連
                            MenuSection(title: "部門") {
                                NavigationItem(
                                    icon: "person.3.fill",
                                    title: "所属部門",
                                    badge: viewModel.user?.departments?.count ?? 0,
                                    color: .cyan
                                ) {
                                    showingSection = .department
                                }
                                
                                NavigationItem(
                                    icon: "plus.circle.fill",
                                    title: "部門を探す",
                                    color: .mint
                                ) {
                                    showDepartmentJoin = true
                                }
                                
                                NavigationItem(
                                    icon: "chart.bar.fill",
                                    title: "部門ランキング",
                                    color: .indigo
                                ) {
                                    // 部門ランキング画面へ
                                }
                            }
                            
                            // 統計・記録
                            MenuSection(title: "統計・記録") {
                                NavigationItem(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "学習統計",
                                    color: .green
                                ) {
                                    // 統計画面へ
                                }
                                
                                NavigationItem(
                                    icon: "trophy.fill",
                                    title: "報酬システム",
                                    color: .yellow
                                ) {
                                    // 報酬システム画面へ
                                }
                                
                                NavigationItem(
                                    icon: "calendar",
                                    title: "学習カレンダー",
                                    color: .red
                                ) {
                                    // カレンダー画面へ
                                }
                            }
                            
                            // 設定
                            MenuSection(title: "設定") {
                                NavigationItem(
                                    icon: "bell.fill",
                                    title: "通知設定",
                                    color: .orange
                                ) {
                                    // 通知設定へ
                                }
                                
                                NavigationItem(
                                    icon: "moon.fill",
                                    title: "テーマ設定",
                                    color: .indigo
                                ) {
                                    // テーマ設定へ
                                }
                                
                                NavigationItem(
                                    icon: "lock.fill",
                                    title: "プライバシー",
                                    color: .gray
                                ) {
                                    // プライバシー設定へ
                                }
                            }
                            
                            // サポート
                            MenuSection(title: "サポート") {
                                NavigationItem(
                                    icon: "bubble.left.and.bubble.right.fill",
                                    title: "フィードバック",
                                    color: .blue
                                ) {
                                    showFeedback = true
                                }
                                
                                NavigationItem(
                                    icon: "questionmark.circle.fill",
                                    title: "ヘルプ",
                                    color: .mint
                                ) {
                                    // ヘルプへ
                                }
                                
                                NavigationItem(
                                    icon: "info.circle.fill",
                                    title: "このアプリについて",
                                    color: .gray
                                ) {
                                    // アプリ情報へ
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 50)
                    }
                }
                .frame(width: 300)
                .background(
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                        .ignoresSafeArea()
                )
                
                Spacer()
            }
            .offset(x: isShowing ? 0 : -300)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
        }
        .sheet(isPresented: $showDepartmentJoin) {
            DepartmentBrowserView()
        }
    }
}

// MARK: - ユーザーヘッダー
struct UserHeaderView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            // アバター
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Text(String(viewModel.user?.nickname.prefix(1) ?? "?"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.user?.nickname ?? "名無し")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    // レベル
                    Label("Lv.\(viewModel.user?.level ?? 1)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    // 所属部門数
                    if let deptCount = viewModel.user?.departments?.count, deptCount > 0 {
                        Label("\(deptCount)部門", systemImage: "person.3.fill")
                            .font(.caption)
                            .foregroundColor(.cyan)
                    }
                }
                
                // トロフィー
                if let trophy = viewModel.user?.currentTrophy {
                    HStack(spacing: 4) {
                        Image(systemName: trophy.icon)
                            .font(.caption)
                            .foregroundColor(trophy.color)
                        Text(trophy.displayName)
                            .font(.caption2)
                            .foregroundColor(trophy.color.opacity(0.8))
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - メニューセクション
struct MenuSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 10)
            
            VStack(spacing: 5) {
                content
            }
        }
    }
}

// MARK: - ナビゲーションアイテム
struct NavigationItem: View {
    let icon: String
    let title: String
    var badge: Int? = nil
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.3))
                        )
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - フィードバック画面
struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackType = "機能要望"
    @State private var feedbackText = ""
    @State private var email = ""
    
    let feedbackTypes = ["バグ報告", "機能要望", "改善提案", "その他"]
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                
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
                        Text("内容")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 150)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    
                    // メールアドレス（任意）
                    VStack(alignment: .leading, spacing: 10) {
                        Text("メールアドレス（任意）")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("返信が必要な場合", text: $email)
                            .textFieldStyle(DarkTextFieldStyle())
                    }
                    
                    Spacer()
                    
                    // 送信ボタン
                    Button(action: sendFeedback) {
                        Text("送信")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                    .disabled(feedbackText.isEmpty)
                }
                .padding()
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
    }
    
    private func sendFeedback() {
        // Firebaseに送信
        // 実装は後で
        dismiss()
    }
}

// MARK: - 部門ブラウザ
struct DepartmentBrowserView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: Department.DepartmentCategory = .study
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                
                VStack(spacing: 0) {
                    // カテゴリ選択
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Department.DepartmentCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 検索バー
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                        
                        TextField("部門を検索", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // 部門リスト
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(PresetDepartments.defaults.filter { 
                                $0.category == selectedCategory 
                            }) { dept in
                                DepartmentCard(department: dept)
                            }
                        }
                        .padding()
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
            }
        }
    }
}

// MARK: - カテゴリチップ
struct CategoryChip: View {
    let category: Department.DepartmentCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected ? Color.blue : Color.white.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
        }
    }
}

// MARK: - 部門カード
struct DepartmentCard: View {
    let department: Department
    @State private var isJoined = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // アイコン
                Image(systemName: department.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: department.color) ?? .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(department.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(department.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 参加ボタン
                Button(action: toggleJoin) {
                    Text(isJoined ? "参加中" : "参加")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isJoined ? Color.green : Color.blue)
                        )
                }
            }
            
            // タグ
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
            
            // メンバー数
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                Text("\(department.memberCount)人参加中")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
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
    
    private func toggleJoin() {
        withAnimation(.spring()) {
            isJoined.toggle()
        }
    }
}

// MARK: - Color Extension
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
