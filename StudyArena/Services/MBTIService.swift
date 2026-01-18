import Foundation
import Firebase
import FirebaseFirestore

class MBTIService {
    private let db = Firestore.firestore()
    
    // ① 書き込み: 勉強が終わったら呼ぶ（足し算するだけ）
    func incrementDailyStats(mbti: String, studyTime: TimeInterval) async throws {
        // 今日の日付 (例: "2026-01-09") - JST基準
        let dateStr = Date().jstDateString 
        let docRef = db.collection("mbtiDailyStats").document(String(dateStr))
        
        // "merge: true" なので、ドキュメントがなければ自動で作られる！
        //docRefで設定した箱にデータをセット
        try await docRef.setData([
            mbti: FieldValue.increment(Double(studyTime)),//studytimeにFieldValueを追加。
            "lastUpdated": Timestamp()
        ], merge: true)
    }
    
    // ② 読み込み: 円グラフ用にデータを取る（1個読むだけ）
    func fetchDailyStats() async throws -> [String: Double] {
        let dateStr = Date().jstDateString
        let doc = try await db.collection("mbtiDailyStats").document(String(dateStr)).getDocument()
        
        guard let data = doc.data() else { return [:] }
        
        var stats: [String: Double] = [:]
        // データからDouble型のものだけ（MBTIごとの時間）を取り出す
        for (key, value) in data {
            if let time = value as? Double {
                stats[key] = time
            }
        }
        return stats
    }
}
