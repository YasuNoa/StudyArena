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
    @State private var showStudyCalendar = false
    @State private var showMBTIStats = false
    @State private var showRewardSystem = false
    @State private var showNotificationSettings = false
    
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
                                    icon: "brain.head.profile",
                                    title: "MBTI別統計",
                                    color: .purple
                                ) {
                                    showMBTIStats = true
                                    isShowing = false
                                }
                                
                                NavigationItem(
                                    icon: "trophy.fill",
                                    title: "報酬システム",
                                    color: Color("yellow")
                                ) {
                                    showRewardSystem = true  // ⭐️ シートを表示
                                    isShowing = false        // ⭐️ サイドメニューを閉じる
                                }
                                NavigationItem(
                                    icon: "calendar",
                                    title: "学習カレンダー",
                                    color: .red
                                ) {
                                    // カレンダー画面へ
                                    showStudyCalendar = true  // ⭐️ シートを表示
                                    isShowing = false
                                }
                            }
                            
                            // 設定
                            NavigationItem(
                                icon: "bell.fill",
                                title: "通知設定",
                                color: Color("orange")
                            ) {
                                showNotificationSettings = true  // 新しいState変数
                                isShowing = false
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
        .sheet(isPresented: $showStudyCalendar) {  // ⭐️ カレンダーシート追加
            NavigationView {
                StudyCalendarView()
                    .environmentObject(viewModel)
                    .navigationTitle("学習カレンダー")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("閉じる") {
                                showStudyCalendar = false
                            }
                            .foregroundColor(.white)
                        }
                    }
            }
        }
        .sheet(isPresented: $showMBTIStats) {
            NavigationView {
                MBTIStatsView()
                    .environmentObject(viewModel)
                    .navigationTitle("MBTI統計")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("閉じる") {
                                showMBTIStats = false
                            }
                            .foregroundColor(.white)
                        }
                    }
            }
        }
        .sheet(isPresented: $showRewardSystem) {
            RewardSystemView()
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsView()
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
