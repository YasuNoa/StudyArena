//
//  otificationManager.swift
//  StudyArena
//
//  Created by 田中正造 on 2026/01/10.
//

import Foundation

class NotificationManager {
    func setupNotifications() {
        // 通知権限をリクエスト
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            print("通知権限: \(granted ? "許可" : "拒否")")
        }
        
        // 通知からの学習開始を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startStudyFromNotification),
            name: .startStudyFromNotification,
            object: nil
        )
    }

}
