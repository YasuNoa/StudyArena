//
//  MinimalDarkBackgroundView.swift
//  StudyArena
//
//  Created by 田中正造 on 11/08/2025.
//


//
//  MinimalDarkBackgroundView.swift
//  productene
//
//  共通の背景ビューコンポーネント
//

import SwiftUI

// ミニマルダーク背景（共通コンポーネント）
struct MinimalDarkBackgroundView: View {
    var body: some View {
        ZStack {
            // ベースグラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 微細なテクスチャ効果
            GeometryReader { geometry in
                // 斜めのグラデーションライン
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.01),
                                    .clear,
                                    .white.opacity(0.005)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geometry.size.width * 2)
                        .rotationEffect(.degrees(45))
                        .offset(x: CGFloat(index) * 100 - 200)
                        .opacity(0.5)
                }
            }
            .ignoresSafeArea()
            
            // 上部のハイライト
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        .white.opacity(0.03),
                        .clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}
