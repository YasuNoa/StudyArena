//
//  TimerView.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//

import SwiftUI
struct TimerView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        ZStack {
            ZStack {
                // ベースとなる深い夜空の色
                Color(red: 0.05, green: 0, blue: 0.1)
                    .ignoresSafeArea()
                
                // 中心から広がる、淡い光のオーラ
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.5),
                        Color.blue.opacity(0.2),
                        .clear
                    ]),
                    center: .center,
                    startRadius: 50,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                // 魔法陣やゲートを思わせる、回転する光
                AngularGradient(
                    gradient: Gradient(colors: [
                        .purple, .blue, .purple, .cyan, .blue, .purple
                    ]),
                    center: .center,
                    angle: .degrees(0)
                )
                .blur(radius: 60) // 光をぼかして、オーラのように見せる
                .opacity(0.7)
                .ignoresSafeArea()
            }
            
            // ▲▲▲▲▲ ここまで差し替え ▲▲▲▲▲
            
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
#Preview {
    TimerView()
        .environmentObject(MainViewModel())
        .previewLayout(.sizeThatFits)
        .padding()
}
