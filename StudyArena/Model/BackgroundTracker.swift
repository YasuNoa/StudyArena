//
//  BackgroundTracker.swift
//  StudyArena
//
//  Created by 田中正造 on 03/08/2025.
//


import Foundation
import UIKit

// バックグラウンド時間追跡クラス
class BackgroundTracker: ObservableObject {
    @Published var backgroundTimeExceeded = false
    @Published var totalBackgroundTime: TimeInterval = 0
    
    private var backgroundStartTime: Date?
    private var maxAllowedBackgroundTime: TimeInterval = 300 // 5分
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        backgroundStartTime = Date()
        print("📱 アプリがバックグラウンドに移行")
    }
    
    @objc private func appWillEnterForeground() {
        guard let startTime = backgroundStartTime else { return }
        
        let backgroundDuration = Date().timeIntervalSince(startTime)
        totalBackgroundTime += backgroundDuration
        
        print("📱 バックグラウンド時間: \(Int(backgroundDuration))秒")
        
        // 5分以上バックグラウンドにいた場合
        if backgroundDuration > maxAllowedBackgroundTime {
            backgroundTimeExceeded = true
            print("⚠️ バックグラウンド時間が制限を超えました")
        }
        
        backgroundStartTime = nil
    }
    
    // セッションリセット
    func resetSession() {
        backgroundTimeExceeded = false
        totalBackgroundTime = 0
        backgroundStartTime = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}