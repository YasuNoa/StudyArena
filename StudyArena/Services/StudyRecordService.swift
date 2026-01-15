//
//  StudyRecordService.swift
//  StudyArena
//
//  Created by 田中正造 on 2026/01/09.
//

import Foundation
import Firebase
import FirebaseFirestore

class StudyRecordService {
    private let db = Firestore.firestore()
    
    // MARK: - 取得系
    
    // 全学習記録を取得（履歴用）
    func fetchStudyRecords(userId: String, limit: Int = 50) async throws -> [StudyRecord] {
        let snapshot = try await db.collection("studyRecords")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        // Codableの力で一発変換
        return snapshot.documents.compactMap { try? $0.data(as: StudyRecord.self) }
    }
    
    // 月間の学習データを取得（カレンダー用）
    func fetchMonthlyRecords(userId: String, month: Date) async throws -> [StudyRecord] {
        let calendar = Calendar.current
        guard let start = calendar.dateInterval(of: .month, for: month)?.start,
              let end = calendar.dateInterval(of: .month, for: month)?.end else { return [] }
        
        let snapshot = try await db.collection("studyRecords")
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("timestamp", isLessThan: Timestamp(date: end))
            .whereField("recordType", isEqualTo: "study")
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: StudyRecord.self) }
    }
    
    // 今日の合計学習時間を取得（タイマー開始時のチェック等）
    func fetchTodayStudyTime(userId: String) async -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let snapshot = try await db.collection("studyRecords")
                .whereField("userId", isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("timestamp", isLessThan: Timestamp(date: tomorrow))
                .whereField("recordType", isEqualTo: "study")
                .getDocuments()
            
            return snapshot.documents.reduce(0.0) { total, doc in
                // durationフィールドをTimeIntervalとして取り出して足す
                let duration = doc.data()["duration"] as? TimeInterval ?? 0
                return total + duration
            }
        } catch {
            return 0
        }
    }
    
    // MARK: - 保存系
    
    // 学習記録を保存
    func saveStudyRecord(_ record: StudyRecord) async throws {
        // Codable準拠なので、そのまま保存可能
        try await db.collection("studyRecords").addDocument(from: record)
    }
}
