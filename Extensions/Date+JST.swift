
import Foundation

extension Date {
    // 日本標準時 (JST) のDateFormatter
    static let jstFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
    
    // JSTのカレンダー
    static let jstCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()
    
    // "yyyy-MM-dd" 形式の文字列 (JST基準) - MBTI統計のIDなどで使用
    var jstDateString: String {
        let formatter = Date.jstFormatter
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    // 表示用: "M月d日 H:mm" (JST)
    var jstDisplayString: String {
        let formatter = Date.jstFormatter
        formatter.dateFormat = "M月d日 H:mm"
        return formatter.string(from: self)
    }
    
    // 表示用: "yyyy年M月d日" (JST)
    var jstDateDisplayString: String {
        let formatter = Date.jstFormatter
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: self)
    }
}
