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
            LinearGradient(
                colors: [.blue.opacity(0.4), .purple.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                if let user = viewModel.user {
                    UserStatusCard(user: user)
                }
                
                TimerDisplay(timeValue: viewModel.timerValue)
                
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
                
                PartnerCard(partner: viewModel.currentPartner)
                
                Spacer()
            }
            .padding()
        }
    }
}
