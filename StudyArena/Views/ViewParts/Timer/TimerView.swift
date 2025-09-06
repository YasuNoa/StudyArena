//
//  TimerView.swift - スクリーンタイム&バックグラウンド追跡版
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var rotation: Double = 0
    @State private var showRewardSystem = false
    
    var body: some View {
        ZStack {
            
            
            VStack(spacing: 30) {
                if let user = viewModel.user {
                    UserStatusCard(user: user)
                        .environmentObject(viewModel)
                }
                
                Spacer()
                
                TimerDisplay(timeValue: viewModel.timerValue)
                
                // ⭐️ 警告表示（バックグラウンド警告のみ）
                if let warning = viewModel.validationWarning {
                    WarningBanner(message: warning)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                TimerButton(
                    isRunning: viewModel.isTimerRunning,
                    onTap: {
                        if viewModel.isTimerRunning {
                            viewModel.stopTimerWithValidation()
                        } else {
                            viewModel.startTimerWithValidation()
                        }
                    }
                )
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // ⭐️ ランキングデータを読み込む（UserStatusCardで使用）
            viewModel.loadRanking()
        }
    }
}

// ⭐️ 警告バナー（シンプル版）
struct WarningBanner: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
    }
}

// 既存のコンポーネントはそのまま保持
struct GateBackgroundView: View {
    @State private var rotation: Double = 0
    @State private var pulsate: Bool = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
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
            
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            ForEach(0..<15, id: \.self) { index in
                ParticleView(delay: Double(index) * 0.3)
            }
        }
    }
}

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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    animateParticle()
                }
            }
        }
    }
}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    TimerView()
        .environmentObject(MainViewModel.mock)
}
#endif
