import Foundation
import FirebaseFirestore

// 学習記録のデータモデル
struct StudyRecord: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let timestamp: Date
    let duration: TimeInterval
    let earnedExperience: Double
    let recordType: RecordType //recordtypeの中に、Recordtype型のなんらかの文字が入っている。
    let beforeLevel: Int
    let afterLevel: Int
    let mbtiType: String?
    
    enum RecordType: String, Codable {
        case study = "study"          // 通常の学習
        case levelUp = "levelUp"      // レベルアップ
        case milestone = "milestone"  // マイルストーン達成
        
        var icon: String {
            switch self {
            case .study: return "book.fill"
            case .levelUp: return "star.fill"
            case .milestone: return "trophy.fill"
            }
        }
        
        var color: String {
            switch self {
            case .study: return "blue"
            case .levelUp: return "yellow"
            case .milestone: return "purple"
            }
        }
    }
    
    // 表示用のフォーマット済み日付
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: timestamp)
    }
    
    // 表示用のフォーマット済み時間
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分\(seconds)秒"
        } else if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
    
    // タイムライン表示用のタイトル
    var title: String {
        switch recordType {
        case .study:
            return "学習を完了"
        case .levelUp:
            return "レベル\(afterLevel)に到達！"
        case .milestone:
            return "マイルストーン達成"
        }
    }
    
    // タイムライン表示用の説明文
    var description: String {
        switch recordType {
        case .study:
            return "\(formattedDuration)の学習で\(Int(earnedExperience))EXPを獲得"
        case .levelUp:
            return "レベル\(beforeLevel)から\(afterLevel)にアップ！"
        case .milestone:
            return "素晴らしい達成です！"
        }
    }
}

// 統計情報
struct StudyStatistics {
    let totalStudyDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageStudyTime: TimeInterval
    let totalRecords: Int
    
    var formattedAverageTime: String {
        let minutes = Int(averageStudyTime) / 60
        return "\(minutes)分"
    }
}
