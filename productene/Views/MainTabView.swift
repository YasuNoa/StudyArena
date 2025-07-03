//
//  MainTabView.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//

import SwiftUI
struct MainTabView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("タイマー")
                }
            
            RankingView()
                .tabItem {
                    Image(systemName: "list.number")
                    Text("ランキング")
                }
            
            HeroSelectionView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("偉人")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("プロフィール")
                }
        }
    }
}
