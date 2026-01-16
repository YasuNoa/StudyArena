//
//  MBTIType.swift
//  StudyArena
//
//  Created by 田中正造 on 2026/01/09.
//

import Foundation

// 文字列ではなく、型として管理する
enum MBTIType: String, Codable, CaseIterable, Identifiable {
    case intj = "INTJ", intp = "INTP", entj = "ENTJ", entp = "ENTP"
    case infj = "INFJ", infp = "INFP", enfj = "ENFJ", enfp = "ENFP"
    case istj = "ISTJ", isfj = "ISFJ", estj = "ESTJ", esfj = "ESFJ"
    case istp = "ISTP", isfp = "ISFP", estp = "ESTP", esfp = "ESFP"
    
    var id: String { self.rawValue }
    
    // 表示名
    var displayName: String {
        switch self {
        case .intj: return "建築家"
        case .intp: return "論理学者"
        case .entj: return "指揮官"
        case .entp: return "討論者"
        case .infj: return "提唱者"
        case .infp: return "仲介者"
        case .enfj: return "主人公"
        case .enfp: return "広報運動家"
        case .istj: return "管理者"
        case .isfj: return "擁護者"
        case .estj: return "幹部"
        case .esfj: return "領事官"
        case .istp: return "巨匠"
        case .isfp: return "冒険家"
        case .estp: return "起業家"
        case .esfp: return "エンターテイナー"
        }
    }
    
    // 説明文
    var description: String {
        switch self {
        case .intj: return "独創的で戦略的な思考を持つ完璧主義者"
        case .intp: return "知識欲旺盛で革新的な発明家"
        case .entj: return "大胆で想像力豊かな強力なリーダー"
        case .entp: return "賢明で好奇心旺盛な思想家"
        case .infj: return "静かで神秘的だが人々を励ますリーダー"
        case .infp: return "詩的で親切、利他的な人"
        case .enfj: return "カリスマ的で人々を導くリーダー"
        case .enfp: return "情熱的で独創的かつ社交的な自由人"
        case .istj: return "実用的で事実に基づいた思考の持ち主"
        case .isfj: return "非常に献身的で心の温かい擁護者"
        case .estj: return "優秀な管理者で、物事や人々を管理する能力に長けている"
        case .esfj: return "非常に思いやりがあり、人気があり、常に熱心に人助けをする"
        case .istp: return "大胆で実践的な思考を持つ実験者"
        case .isfp: return "柔軟で魅力的な芸術家"
        case .estp: return "賢く、エネルギッシュで、非常に鋭い知覚の持ち主"
        case .esfp: return "自発的でエネルギッシュで熱心なエンターテイナー"
        }
    }
}

// MBTI統計データ構造体
struct MBTIStatData: Identifiable {
    let id = UUID()
    let mbtiType: String
    let totalTime: Double
    let userCount: Int
    let avgTime: Double
    
    init(mbtiType: String, totalTime: Double, userCount: Int, avgTime: Double) {
        self.mbtiType = mbtiType
        self.totalTime = totalTime
        self.userCount = userCount
        self.avgTime = avgTime
    }
}
