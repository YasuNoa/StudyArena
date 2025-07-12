//
//  TimerView.swift - ゲート風バージョン
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            
            MinimalDarkBackgroundView()
            
            VStack(spacing: 30) {
                if let user = viewModel.user {
                    UserStatusCard(user: user)
                }
                Spacer()
                
                TimerDisplay(timeValue: viewModel.timerValue)
                
                Spacer()
                TimerButton(
                    isRunning: viewModel.isTimerRunning,
                    onTap: {
                        if viewModel.isTimerRunning {
                            viewModel.stopTimer()
                        } else {
                            viewModel.startTimer()
                        }
                    }
                )
                Spacer()
            }
            .padding()
        }
    }
}

// ゲート風背景
struct GateBackgroundView: View {
    @State private var rotation: Double = 0
    @State private var pulsate: Bool = false
    
    var body: some View {
        ZStack {
            // ベース: より深い闇
            Color.black
                .ignoresSafeArea()
            
            // 中心の青い光（ゲートの核）- 脈動効果付き
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.8),
                    Color.blue.opacity(0.4),
                    Color.purple.opacity(0.2),
                    .clear
                ]),
                center: .center,
                startRadius: pulsate ? 40 : 30,
                endRadius: pulsate ? 320 : 300
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulsate = true
                }
            }
            
            // 回転する魔法陣（内側）
            AngularGradient(
                gradient: Gradient(colors: [
                    .cyan, .blue, .purple, .blue, .cyan
                ]),
                center: .center,
                angle: .degrees(rotation)
            )
            .blur(radius: 40)
            .opacity(0.5)
            .ignoresSafeArea()
            .rotationEffect(.degrees(rotation))
            
            // 回転する魔法陣（外側）- 逆回転
            AngularGradient(
                gradient: Gradient(colors: [
                    .purple, .cyan, .blue, .cyan, .purple
                ]),
                center: .center,
                angle: .degrees(-rotation * 0.7)
            )
            .blur(radius: 60)
            .opacity(0.3)
            .ignoresSafeArea()
            .rotationEffect(.degrees(-rotation * 0.7))
            
            // アニメーション開始
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            // パーティクル効果
            ForEach(0..<15, id: \.self) { index in
                ParticleView(delay: Double(index) * 0.3)
            }
        }
    }
}

// パーティクルエフェクト
struct ParticleView: View {
    let delay: Double
    @State private var offset = CGSize.zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [.cyan, .blue]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 3
                )
            )
            .frame(width: CGFloat.random(in: 3...6))
            .opacity(opacity)
            .offset(offset)
            .blur(radius: 1)
            .onAppear {
                animateParticle()
            }
    }
    
    private func animateParticle() {
        let startX = CGFloat.random(in: -200...200)
        let startY = CGFloat.random(in: 200...400)
        
        offset = CGSize(width: startX, height: startY)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: Double.random(in: 4...7))) {
                offset = CGSize(
                    width: startX + CGFloat.random(in: -50...50),
                    height: -400
                )
                opacity = Double.random(in: 0.4...0.8)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 2)) {
                    opacity = 0
                }
                
                // 再度アニメーション
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    animateParticle()
                }
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    TimerView()
        .environmentObject(MainViewModel.mock)
}
