//
//  Department.swift
//  StudyArena
//
//  Created by 田中正造 on 17/08/2025.
//


// StudyArena/Model/Department.swift

import Foundation
import FirebaseFirestore

// MARK: - 部門モデル
struct Department: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var icon: String // SF Symbolsのアイコン名
    var color: String // カラーコード
    var memberCount: Int = 0
    var createdAt: Date = Date()
    var tags: [String] = [] // タグ（例: ["高校生", "理系", "朝活"]）
    
    // 部門のカテゴリ
    var category: DepartmentCategory
    
    enum DepartmentCategory: String, Codable, CaseIterable {
        case study = "学習"
        case hobby = "趣味"
        case work = "仕事"
        case health = "健康"
        case other = "その他"
        
        var displayName: String {
            switch self {
            case .study: return "学習"
            case .hobby: return "趣味"
            case .work: return "仕事"
            case .health: return "健康"
            case .other: return "その他"
            }
        }
    }
}

// MARK: - 部門メンバーシップ
struct DepartmentMembership: Codable {
    let departmentId: String
    let departmentName: String
    let joinedAt: Date
    var role: MemberRole = .member
    
    enum MemberRole: String, Codable {
        case owner = "owner"
        case admin = "admin"
        case member = "member"
    }
}

// MARK: - ユーザーモデルの拡張
extension User {
    // 既存のUserモデルに追加するプロパティ
    // var departments: [DepartmentMembership] = []
    // var primaryDepartmentId: String? // メイン部門
}

// MARK: - ランキングフィルター
enum RankingFilter: String, CaseIterable {
    case all = "全体"
    case department = "部門"
    case age = "年齢別"
    case monthly = "今月"
    case weekly = "今週"
    case daily = "今日"
    
    var icon: String {
        switch self {
        case .all: return "globe"
        case .department: return "person.3.fill"
        case .age: return "calendar"
        case .monthly: return "calendar.badge.clock"
        case .weekly: return "calendar.circle"
        case .daily: return "sun.max.fill"
        }
    }
}

// MARK: - プリセット部門（初期データ）
struct PresetDepartments {
    static let defaults: [Department] = [
        // 学習系
        Department(
            name: "大学受験部",
            description: "大学受験に向けて頑張る仲間が集まる部門",
            icon: "graduationcap.fill",
            color: "#FF6B6B",
            tags: ["受験", "高校生", "大学"], category: .study
        ),
        Department(
            name: "資格勉強部",
            description: "各種資格取得を目指す部門",
            icon: "doc.text.fill",
            color: "#4ECDC4",
            tags: ["資格", "社会人", "スキルアップ"], category: .study
        ),
        Department(
            name: "プログラミング部",
            description: "コーディングスキルを磨く部門",
            icon: "chevron.left.forwardslash.chevron.right",
            color: "#95E77E",
            tags: ["プログラミング", "IT", "エンジニア"], category: .study
        ),
        
        // 健康系
        Department(
            name: "朝活部",
            description: "早朝の学習習慣を作る部門",
            icon: "sunrise.fill",
            color: "#FFE66D",
            tags: ["朝活", "早起き", "習慣"], category: .health
        ),
        Department(
            name: "ポモドーロ部",
            description: "25分集中法を実践する部門",
            icon: "timer",
            color: "#A8E6CF",
            tags: ["ポモドーロ", "集中", "効率"], category: .health
        ),
        
        // 趣味系
        Department(
            name: "読書部",
            description: "読書習慣を共有する部門",
            icon: "book.fill",
            color: "#C9B1FF",
            tags: ["読書", "教養", "趣味"], category: .hobby
        ),
        Department(
            name: "語学学習部",
            description: "外国語学習に取り組む部門",
            icon: "globe.americas.fill",
            color: "#FFB1B1",
            tags: ["語学", "英語", "外国語"], category: .study
        ),
        
        // その他
        Department(
            name: "フリーランス部",
            description: "フリーランスの仕事術を共有",
            icon: "laptopcomputer",
            color: "#B4A7D6",
            tags: ["フリーランス", "仕事", "独立"], category: .work
        ),
        Department(
            name: "夜型部",
            description: "夜に集中して学習する部門",
            icon: "moon.stars.fill",
            color: "#8E8E93",
            tags: ["夜型", "深夜", "集中"], category: .other
        )
    ]
}
