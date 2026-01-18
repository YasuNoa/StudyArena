//
//  LoadingView.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            MinimalDarkBackgroundView()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("データを読み込み中...")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
    }
}
#Preview {
    LoadingView()
}
