//
//  RankingViewModel.swift
//  StudyArena
//
//  Created by User on 2026/01/16.
//

import Foundation
import Combine

@MainActor
class RankingViewModel: ObservableObject {
    @Published var ranking: [User] = []
    @Published var isLoading: Bool = false
    
    // DBとのやりとりはServiceに任せる
    private let userService = UserService()
    
    func loadRanking() async {
        isLoading = true
        // Serviceからデータを取得（DBアクセス）
        let fetchedRanking = await userService.loadRanking()
        self.ranking = fetchedRanking
        isLoading = false
    }
}