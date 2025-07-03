//
//  UserStatusCard.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

struct UserStatusCard: View {
    let user: User
    
    var body: some View {
        HStack {
            Text("Lv. \(user.level)")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                ProgressView(value: user.experience, total: user.experienceForNextLevel)
                    .tint(.yellow)
                    .frame(width: 150)
                
                Text("EXP: \(Int(user.experience)) / \(Int(user.experienceForNextLevel))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

