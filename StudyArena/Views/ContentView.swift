// FileName: ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(errorMessage: errorMessage) {
                    // リトライ機能
                    viewModel.retryAuthentication()
                }
            } else {
                MainTabView()
                    .environmentObject(viewModel)
            }
        }
    }
}

// ContentView.swift の一番下
#Preview {
    ContentView()
}
