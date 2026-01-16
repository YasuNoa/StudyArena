import Foundation
import Combine

    
// 学習パターン、時間帯分析、継続性などを将来実装していきたい！

@MainActor
class StudyRecordViewModel: ObservableObject {
    
    // データソース：これが変わると統計も自動再計算される
    @Published var studyRecords: [StudyRecord] = [] {
        didSet {
            calculateStatistics()
            analyzePatterns()
        }
    }
    
    // 画面表示用データ
    @Published var studyStatistics: StudyStatistics?
    @Published var dailyStudyData: [Date: TimeInterval] = [:] // カレンダー用
    @Published var learningPattern: LearningPattern?
    @Published var isLoading: Bool = false
    
    // 外部からセットする情報
    var userId: String?
    var user: User? // MBTI情報などが必要な場合用
    
    private let service = StudyRecordService()
    
    // MARK: - データ読み込み
    
    // 履歴リストの読み込み
    func loadRecords() {
        // プレビュー判定
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview {
            self.studyRecords = createMockStudyRecords()
            return
        }
        
        guard let uid = userId else { return }
        
        self.isLoading = true
        Task {
            do {
                let records = try await service.fetchStudyRecords(userId: uid)
                self.studyRecords = records // ここでdidSetが発火→統計計算
                self.isLoading = false
            } catch {
                print("学習記録読み込みエラー: \(error)")
                self.isLoading = false
            }
        }
    }
    
    // カレンダー用の月間データ読み込み
    func loadMonthlyData(for month: Date) {
        guard let uid = userId else { return }
        
        Task {
            do {
                let records = try await service.fetchMonthlyRecords(userId: uid, month: month)
                
                // 日付ごとに集計して dailyStudyData に入れる
                let calendar = Calendar.current
                var dailyData: [Date: TimeInterval] = [:]
                
                for record in records {
                    let day = calendar.startOfDay(for: record.timestamp)
                    dailyData[day] = (dailyData[day] ?? 0) + record.duration
                }
                
                self.dailyStudyData = dailyData
            } catch {
                print("月間データ取得エラー: \(error)")
            }
        }
    }
    
    // MARK: - アクション
    
    // 学習完了時に保存する（MainViewModelから呼ばれる想定）
    func saveRecord(duration: TimeInterval, earnedExp: Double, beforeLevel: Int, afterLevel: Int) async {
        guard let uid = userId else { return }
        
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview { return }
        
        let recordType: StudyRecord.RecordType = (beforeLevel < afterLevel) ? .levelUp : .study
        
        // 新しいモデルを使ってインスタンス作成
        let record = StudyRecord(
            userId: uid,
            timestamp: Date(),
            duration: duration,
            earnedExperience: earnedExp,
            recordType: recordType,
            beforeLevel: beforeLevel,
            afterLevel: afterLevel,
            mbtiType: user?.mbtiType
        )
        
        do {
            // Service経由で保存
            try await service.saveStudyRecord(record)
            
            // 保存成功したら、ローカルのリストの先頭に追加（-> 自動で統計再計算）
            self.studyRecords.insert(record, at: 0)
        } catch {
            print("保存エラー: \(error)")
        }
    }
    
    // MARK: - 計算ロジック (Private)
    
    private func calculateStatistics() {
        guard !studyRecords.isEmpty else {
            studyStatistics = nil
            return
        }
        
        let calendar = Calendar.current
        // 日付ごとにグループ化
        let recordsByDate = Dictionary(grouping: studyRecords) { record in
            calendar.startOfDay(for: record.timestamp)
        }
        
        let totalStudyDays = recordsByDate.count
        
        // 継続日数の計算
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // もし今日勉強してないなら、昨日からチェック開始
        if recordsByDate[checkDate] == nil {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        while recordsByDate[checkDate] != nil {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        // 平均時間
        let totalTime = studyRecords.reduce(0) { $0 + $1.duration }
        let averageTime = totalStudyDays > 0 ? totalTime / Double(totalStudyDays) : 0
        
        // モデルの struct StudyStatistics を使用
        self.studyStatistics = StudyStatistics(
            totalStudyDays: totalStudyDays,
            currentStreak: currentStreak,
            longestStreak: currentStreak, // 簡易実装（本来は過去ログ全て見る必要あり）
            averageStudyTime: averageTime,
            totalRecords: studyRecords.count
        )
    }
    
    // 学習パターンの分析
    private func analyzePatterns() {
        // StudyRecord -> StudySession に変換して分析関数に渡す
        let sessions = studyRecords.map { StudySession(duration: $0.duration, timestamp: $0.timestamp) }
        self.learningPattern = analyzeLearningPattern(from: sessions)
    }
    
    private func analyzeLearningPattern(from sessions: [StudySession]) -> LearningPattern {
        guard !sessions.isEmpty else {
            return LearningPattern(averageSessionDuration: 0, preferredStudyHour: 0, consistencyScore: 0, totalSessions: 0)
        }
        
        let calendar = Calendar.current
        let avgDuration = sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count)
        
        let hourCounts = sessions.reduce(into: [Int: Int]()) { result, session in
            let hour = calendar.component(.hour, from: session.timestamp)
            result[hour, default: 0] += 1
        }
        let preferredHour = hourCounts.max(by: { $0.value < $1.value })?.key ?? 0
        
        let dailySessions = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.timestamp)
        }
        let consistency = calculateConsistencyScore(from: Array(dailySessions.keys))
        
        return LearningPattern(
            averageSessionDuration: avgDuration,
            preferredStudyHour: preferredHour,
            consistencyScore: consistency,
            totalSessions: sessions.count
        )
    }
    
    private func calculateConsistencyScore(from studyDates: [Date]) -> Double {
        guard studyDates.count > 1 else { return 0 }
        let sortedDates = studyDates.sorted()
        let intervals = zip(sortedDates, sortedDates.dropFirst()).map { $1.timeIntervalSince($0) }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.reduce(0) { sum, interval in sum + pow(interval - avgInterval, 2) } / Double(intervals.count)
        let deviation = sqrt(variance)
        return deviation > 0 ? min(1.0, 1.0 / (deviation / 86400)) : 1.0
    }
    
    // MARK: - モックデータ (プレビュー用)
    private func createMockStudyRecords() -> [StudyRecord] {
        var records: [StudyRecord] = []
        let calendar = Calendar.current
        
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            records.append(StudyRecord(
                id: "mock\(i)",
                userId: "mockUser",
                timestamp: date,
                duration: 3600,
                earnedExperience: 100,
                recordType: .study,
                beforeLevel: 10,
                afterLevel: 10,
                mbtiType: "INTJ"
            ))
        }
        return records
    }
}
