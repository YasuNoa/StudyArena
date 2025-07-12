//
//  MainTabView.swift - フローティングボタン風
//  productene
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedTab: Tab = .timer
    
    enum Tab: Int, CaseIterable {
        case timer = 0
        case ranking = 1
        case profile = 2
        
        var title: String {
            switch self {
            case .timer: return "タイマー"
            case .ranking: return "ランキング"
            case .profile: return "プロフィール"
            }
        }
        
        var icon: String {
            switch self {
            case .timer: return "timer"
            case .ranking: return "crown.fill"
            case .profile: return "person.fill"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .timer: return [.blue, .cyan]
            case .ranking: return [.orange, .yellow]
            case .profile: return [.purple, .pink]
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // メインコンテンツ
            Group {
                switch selectedTab {
                case .timer:
                    TimerView()
                case .ranking:
                    RankingView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // フローティングTabBar
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 15) {
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
            // すりガラス効果の背景
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
                // 背景
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
                    .frame(width: isSelected ? 110 : 90, height: 55)
                    .shadow(
                        color: isSelected ? tab.gradient[0].opacity(0.4) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                // コンテンツ
                HStack(spacing: 8) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    
                    if isSelected {
                        Text(tab.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, isSelected ? 12 : 0)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
#Preview {
    MainTabView()
        .environmentObject(MainViewModel.mock)
}
