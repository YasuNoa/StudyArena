//タイマーが終了した場所（TimerManager か MainViewModel）で、recordStudyTime を呼んであげる。

import Foundation
import Combine

@MainActor
class MBTIViewModel: ObservableObject {
    
    // 円グラフに渡すデータ (MBTI名 : 統計データ)
    @Published var mbtiStatistics: [String: MBTIStatData] = [:]
    @Published var isLoading: Bool = false
    
    private let service = MBTIService()
    
    // 画面が表示されたら呼ぶ
    func loadData() {
        self.isLoading = true
        Task {
            do {
                let stats = try await service.fetchDailyStats()
                // [String: Double] -> [String: MBTIStatData] への変換
                let convertedStats = stats.mapValues { time in
                    MBTIStatData(
                        mbtiType: "Unknown", // キーで上書きされるか、initで渡すか。Mapのkeyを使う必要がある
                        totalTime: time,
                        userCount: 0, // 簡易版なのでダミー
                        avgTime: 0    // 簡易版なのでダミー
                    )
                }
                
                // key情報をMBTIStatDataにも反映させる（mapValuesだとvalueしか見えないが、再生成時にキーを使うのが本当は良い）
                var finalStats: [String: MBTIStatData] = [:]
                for (key, value) in convertedStats {
                    finalStats[key] = MBTIStatData(
                        mbtiType: key,
                        totalTime: value.totalTime,
                        userCount: 1, // サンプルとして1人とするか
                        avgTime: value.totalTime // 1人なら平均＝合計
                    )
                }
                
                self.mbtiStatistics = finalStats
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
    // MBTI情報のヘルパー
    static func getMBTIInfo(_ type: String) -> (name: String, description: String) {
        if let mbti = MBTIType(rawValue: type) {
            return (mbti.displayName, mbti.description)
        }
        return ("不明", "")
    }

    // MBTIタイプ更新 (UserServiceを使用)
    func updateMBTIType(userId: String, type: String?) async throws {
        let userService = UserService()
        try await userService.updateMBTI(userId: userId, mbti: type)
        // ここでのローカル更新はViewModelの責任範囲外（MainViewModelのUserを更新できないため）
        // 呼び出し元で再取得などを行う必要がある
    }
}
