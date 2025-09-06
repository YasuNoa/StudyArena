//
//  Feedback.swift
//  StudyArena
//
//  Created by 田中正造 on 2025/09/06.
//


import Foundation
import FirebaseFirestore
import UIKit
import SwiftUI

struct Feedback: Codable {
    @DocumentID var id: String?
    let userId: String?
    let userNickname: String?
    let userLevel: Int?
    let feedbackType: String
    let content: String
    let email: String?
    let timestamp: Date
    let deviceInfo: String
    let appVersion: String
    let status: FeedbackStatus
    
    enum FeedbackStatus: String, Codable {
        case pending = "pending"
        case reviewing = "reviewing"
        case resolved = "resolved"
        case dismissed = "dismissed"
    }
}