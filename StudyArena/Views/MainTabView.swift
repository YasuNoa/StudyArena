// StudyArena/Views/MainTabView.swift - 更新版

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedTab: Tab = .timer
    @State private var showSideMenu = false
    
    // Navigation States
    @State private var showMBTIPatterns = false
    @State private var showMBTIStats = false
    @State private var showDepartmentJoin = false
    @State private var showCreateDepartment = false
    @State private var showMyDepartments = false // ⭐️ 追加
    @State private var showStudyStatistics = false
    @State private var showStudyCalendar = false
    @State private var showRewardSystem = false
    @State private var showNotificationSettings = false
    @State private var showFeedback = false
    
    @StateObject private var departmentViewModel = DepartmentViewModel()
    
    enum Tab: Int, CaseIterable {
        case timer = 0
        case ranking = 1
        case timeline = 2
        case profile = 3
        
        var title: String {
            switch self {
            case .timer: return "タイマー"
            case .ranking: return "全国ランキング"
            case .timeline: return "タイムライン"
            case .profile: return "プロフィール"
            }
        }
        
        var icon: String {
            switch self {
            case .timer: return "timer"
            case .ranking: return "crown.fill"
            case .timeline: return "clock.arrow.circlepath"
            case .profile: return "person.fill"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .timer: return [.blue, .cyan]
            case .ranking: return [.orange, .yellow]
            case .timeline: return [.green, .mint]
            case .profile: return [.purple, .pink]
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack { // ← ZStackで全体を囲む
                // ① 一番下に背景を一度だけ配置
                MinimalDarkBackgroundView()
                    .ignoresSafeArea()
                
                // NavigationLink (非表示)
                // NavigationLinks (非表示)
                Group {
                    NavigationLink(isActive: $showMBTIPatterns) { MBTIStatsView() } label: { EmptyView() }
                    NavigationLink(isActive: $showMBTIStats) { MBTIStatsView() } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showDepartmentJoin) {
                        DepartmentBrowserView()
                            .environmentObject(viewModel)
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showCreateDepartment) {
                        CreateDepartmentView(departmentViewModel: departmentViewModel)
                            .onAppear {
                                departmentViewModel.userId = viewModel.user?.id
                                departmentViewModel.user = viewModel.user
                            }
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showMyDepartments) { // ⭐️ 追加
                        MyDepartmentListView(departmentViewModel: departmentViewModel)
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showStudyStatistics) {
                        StudyStatisticsView().environmentObject(viewModel)
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showStudyCalendar) {
                        StudyCalendarView().environmentObject(viewModel)
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showRewardSystem) { RewardSystemView() } label: { EmptyView() }
                    NavigationLink(isActive: $showNotificationSettings) { NotificationSettingsView() } label: { EmptyView() }
                    NavigationLink(isActive: $showFeedback) { FeedbackView() } label: { EmptyView() }
                }
                
                ZStack(alignment: .bottom) {
                    // メインコンテンツ
                    VStack(spacing: 0) {
                        // 上部ナビゲーションバー
                        TopNavigationBar(showSideMenu: $showSideMenu, currentTab: $selectedTab)
                            .padding(.top, 10) // ステータスバーとの余白
                        
                        // コンテンツエリア
                        Group {
                            switch selectedTab {
                            case .timer:
                                TimerView()
                            case .ranking:
                                RankingView()
                            case .timeline:
                                TimelineView()
                            case .profile:
                                ProfileView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.horizontal, 20) // コンテンツに強めの横余白
                    .padding(.bottom, 80) // タブバー分の余白確保
                    
                    // フローティングTabBar
                    FloatingTabBar(selectedTab: $selectedTab)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    
                    // サイドメニューオーバーレイ
                    SideNavigationView(
                        isShowing: $showSideMenu,
                        selectedTab: $selectedTab,
                        showFeedback: $showFeedback,
                        showDepartmentJoin: $showDepartmentJoin,
                        showStudyCalendar: $showStudyCalendar,
                        showMBTIStats: $showMBTIStats,
                        showMBTIPatterns: $showMBTIPatterns,
                        showMyDepartments: $showMyDepartments,
                        showRewardSystem: $showRewardSystem,
                        showNotificationSettings: $showNotificationSettings,
                        showCreateDepartment: $showCreateDepartment,
                        showStudyStatistics: $showStudyStatistics
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        // 各画面から戻った時にサイドメニューを再表示する
        .onChange(of: showMBTIPatterns) { if !$0 { showSideMenu = true } }
        .onChange(of: showMBTIStats) { if !$0 { showSideMenu = true } }
        .onChange(of: showDepartmentJoin) { if !$0 { showSideMenu = true } }
        .onChange(of: showCreateDepartment) { if !$0 { showSideMenu = true } }
        .onChange(of: showMyDepartments) { if !$0 { showSideMenu = true } }
        .onChange(of: showStudyStatistics) { if !$0 { showSideMenu = true } }
        .onChange(of: showStudyCalendar) { if !$0 { showSideMenu = true } }
        .onChange(of: showRewardSystem) { if !$0 { showSideMenu = true } }
        .onChange(of: showNotificationSettings) { if !$0 { showSideMenu = true } }
        .onChange(of: showFeedback) { if !$0 { showSideMenu = true } }
    }
}

// MARK: - 上部ナビゲーションバー
struct TopNavigationBar: View {
    @Binding var showSideMenu: Bool
    @Binding var currentTab: MainTabView.Tab // ⭐️ Bindingに変更
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        HStack {
            // メニューボタン
            Button(action: {
                withAnimation(.spring()) {
                    showSideMenu.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // 現在のタブ名（タップでプロフィールへ）
            Text(currentTab.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .onTapGesture { 
                    withAnimation {
                        currentTab = .profile
                    }
                }
            
            Spacer()
            
            // 通知ボタン（将来的な拡張用）
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // 通知バッジ（ある場合）
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 10, y: -10)
                        .opacity(0) // 今は非表示
                }
            }
            .disabled(true) // 今は無効
        }
        .background(Color.clear)
    }
}

// 既存のFloatingTabBarはそのまま使用
struct FloatingTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                FloatingTabButton(
                    tab: tab,
                    selectedTab: $selectedTab,
                    animation: animation
                )
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
    }
}

struct FloatingTabButton: View {
    let tab: MainTabView.Tab
    @Binding var selectedTab: MainTabView.Tab
    let animation: Namespace.ID
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: tab.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isSelected ? 100 : 75, height: 50)
                    .shadow(
                        color: isSelected ? tab.gradient[0].opacity(0.4) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                HStack(spacing: 6) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    
                    if isSelected {
                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, isSelected ? 10 : 0)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
#Preview{
    MainTabView()
        .environmentObject(MainViewModel())
}
