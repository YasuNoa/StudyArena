//
//  TimerDisplay.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

struct TimerDisplay: View {
    let timeValue: TimeInterval
    
    var body: some View {
        Text(formatTime(timeValue))
            .font(.system(size: 64, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
#Preview(traits: .sizeThatFitsLayout) {
    TimerDisplay(timeValue: 3661) // Example time value of 1 hour, 1 minute, and 1 second
        .padding()
        .background(Color.blue.opacity(0.8))
        .cornerRadius(12)
}
        
