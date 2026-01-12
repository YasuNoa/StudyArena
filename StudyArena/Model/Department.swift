//
//  Department.swift
//  StudyArena
//
//  Created by 田中正造 on 17/08/2025.
//

import Foundation
import FirebaseFirestore

// MARK: - 部門モデル
struct Department: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String                    // 部門名
    var description: String             // 部門の詳細説明
    var creatorName: String            // 作成者の名前
    var creatorId: String              // 作成者のUUID（リーダー）
    var createdAt: Date = Date()       // 作成日
    var memberCount: Int = 1           // メンバー数（作成者含む）
    var tags: [String] = []            // タグ（最大3つ）
    var isOpenToAll: Bool = true       // true: 誰でも参加可能, false: 承認制
    var pendingRequests: [String] = [] // 承認待ちのユーザーID
    var maxMembers: Int = 20           // 最大メンバー数
    
    // 初期化用
    init(name: String, description: String, creatorName: String, creatorId: String, tags: [String] = [], isOpenToAll: Bool = true) {
        self.name = name
        self.description = description
        self.creatorName = creatorName
        self.creatorId = creatorId
        self.createdAt = Date()
        self.memberCount = 1
        self.tags = tags
        self.isOpenToAll = isOpenToAll
        self.maxMembers = 20
        self.pendingRequests = []
    }
    
    // 定員に達しているか
    var isFull: Bool {
        return memberCount >= maxMembers
    }
}

// MARK: - 部門メンバーシップ（ユーザーがどの部門に所属しているか）
struct DepartmentMembership: Identifiable, Codable {
    var id: String { "\(userId)_\(departmentId)" }
    let userId: String
    let departmentId: String
    let departmentName: String
    let joinedAt: Date
    var role: MemberRole = .member  // メンバーの役割
    
    // 初期化用
    init(userId: String, departmentId: String, departmentName: String, role: MemberRole = .member) {
        self.userId = userId
        self.departmentId = departmentId
        self.departmentName = departmentName
        self.joinedAt = Date()
        self.role = role
    }
}

// MARK: - メンバーの役割
enum MemberRole: String, Codable {
    case leader = "leader"           // リーダー（1人のみ、譲渡可能）
    case subLeader = "subLeader"     // サブリーダー
    case elder = "elder"             // エルダー
    case member = "member"           // メンバー
    
    var displayName: String {
        switch self {
        case .leader: return "リーダー"
        case .subLeader: return "サブリーダー"
        case .elder: return "エルダー"
        case .member: return "メンバー"
        }
    }
    
    var icon: String {
        switch self {
        case .leader: return "👑"
        case .subLeader: return "⭐️"
        case .elder: return "🔷"
        case .member: return "👤"
        }
    }
    
    // 招待権限があるか
    var canInvite: Bool {
        switch self {
        case .leader, .subLeader, .elder: return true
        case .member: return false
        }
    }
    
    // 役割の順序（表示用）
    var sortOrder: Int {
        switch self {
        case .leader: return 0
        case .subLeader: return 1
        case .elder: return 2
        case .member: return 3
        }
    }
}

// MARK: - 部門メンバー詳細情報（表示用）
struct DepartmentMember: Identifiable {
    let id: String  // userId
    let nickname: String
    let level: Int
    let role: MemberRole
    let joinedAt: Date
    let totalStudyTime: TimeInterval
    
    var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: joinedAt)
    }
}

// MARK: - トロフィーレベル（部門作成権限チェック用）
enum TrophyLevel: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"
    
    var displayName: String {
        switch self {
        case .bronze: return "ブロンズ"
        case .silver: return "シルバー"
        case .gold: return "ゴールド"
        case .platinum: return "プラチナ"
        case .diamond: return "ダイヤモンド"
        }
    }
    
    // 部門作成権限があるかチェック
    var canCreateDepartment: Bool {
        switch self {
        case .bronze, .silver:
            return false
        case .gold, .platinum, .diamond:
            return true
        }
    }
    
    // レベルの順序（上位ほど大きい値）
    var order: Int {
        switch self {
        case .bronze: return 1
        case .silver: return 2
        case .gold: return 3
        case .platinum: return 4
        case .diamond: return 5
        }
    }
}
