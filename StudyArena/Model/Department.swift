//
//  Department.swift
//  StudyArena
//
//  Created by 田中正造 on 17/08/2025.
//

import Foundation
import FirebaseFirestore

// MARK: - シンプルな部門モデル
struct Department: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String                    // 部門名
    var description: String             // 部門の詳細説明
    var creatorName: String            // 作成者の名前
    var creatorId: String              // 作成者のUUID
    var createdAt: Date = Date()       // 作成日
    var memberCount: Int = 1           // メンバー数（作成者含む）
    
    // 初期化用
    init(name: String, description: String, creatorName: String, creatorId: String) {
        self.name = name
        self.description = description
        self.creatorName = creatorName
        self.creatorId = creatorId
        self.createdAt = Date()
        self.memberCount = 1
    }
}

// MARK: - 部門メンバーシップ（ユーザーがどの部門に所属しているか）
struct DepartmentMembership: Identifiable, Codable {
    var id: String { "\(userId)_\(departmentId)" }
    let userId: String
    let departmentId: String
    let departmentName: String
    let joinedAt: Date
    
    // 初期化用（roleパラメータなし）
    init(userId: String, departmentId: String, departmentName: String) {
        self.userId = userId
        self.departmentId = departmentId
        self.departmentName = departmentName
        self.joinedAt = Date()
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
