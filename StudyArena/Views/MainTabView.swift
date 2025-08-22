// StudyArena/Views/MainTabView.swift - 更新版

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedTab: Tab = .timer
    @State private var showSideMenu = false
    
    enum Tab: Int, CaseIterable {
        case timer = 0
        case ranking = 1
        case timeline = 2
        case profile = 3
        
        var title: String {
            switch self {
            case .timer: return "タイマー"
            case .ranking: return "ランキング"
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
        ZStack(alignment: .bottom) {
            // メインコンテンツ
            VStack(spacing: 0) {
                // 上部ナビゲーションバー
                TopNavigationBar(showSideMenu: $showSideMenu, currentTab: selectedTab)
                
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
            
            // フローティングTabBar
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            
            // サイドメニューオーバーレイ
            SideNavigationView(
                isShowing: $showSideMenu,
                selectedTab: $selectedTab
            )
        }
    }
}

// MARK: - 上部ナビゲーションバー
struct TopNavigationBar: View {
    @Binding var showSideMenu: Bool
    let currentTab: MainTabView.Tab
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
            
            // 現在のタブ名
            Text(currentTab.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
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
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
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
