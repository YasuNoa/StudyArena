//タイマーが終了した場所（TimerManager か MainViewModel）で、recordStudyTime を呼んであげる。

import Foundation
import Combine

@MainActor
class MBTIViewModel: ObservableObject {
    
    // 円グラフに渡すデータ (MBTI名 : 秒数)
    @Published var dailyStats: [String: Double] = [:]
    @Published var isLoading: Bool = false
    
    private let service = MBTIService()
    
    // 画面が表示されたら呼ぶ
    func loadData() {
        self.isLoading = true
        Task {
            do {
                let stats = try await service.fetchDailyStats()
                self.dailyStats = stats
                self.isLoading = false
            } catch {
                print("エラー: \(error)")
                self.isLoading = false
            }
        }
    }
    
    // 【重要】タイマー停止時に呼ぶやつ
    func recordStudyTime(mbti: String, time: TimeInterval) {
        Task {
            try? await service.incrementDailyStats(mbti: mbti, studyTime: time)
            // 更新後に再読み込みしてグラフを最新にする
            loadData()
        }
    }
}
