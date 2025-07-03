//
//  TimerButton.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

struct TimerButton: View {
    let isRunning: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(isRunning ? "STOP" : "START")
                .font(.title)
                .fontWeight(.bold)
                .frame(width: 180, height: 180)
                .background(isRunning ? Color.red : Color.green)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .scaleEffect(isRunning ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isRunning)
    }
}
