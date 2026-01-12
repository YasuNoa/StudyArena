//
//  TimerManager.swift
//  StudyArena
//
//  Created by 田中正造 on 2026/01/10.
//

import Foundation


class TimerManager: ObservableObject {
    @Published var timerValue: TimeInterval = 0
    
    @Published var isTimerRunning: Bool = false
    
    @Published var backgroundTracker = BackgroundTracker()
    
    @Published var validationWarning: String?
    
    private var timer: Timer?
    
    // タイマーが正常終了した時に呼ばれる。「何秒勉強したか」を渡す。
    var onTimerCompleted: ((TimeInterval) -> Void)?
    
    func startTimerWithValidation() {
        
        guard !isTimerRunning else { return }
        
        
        
        // バックグラウンド追跡リセット
        
        backgroundTracker.resetSession()
        
        
        
        
        
        isTimerRunning = true
        
        timer?.invalidate()
        
        
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            
            Task { @MainActor in
                
                self?.timerValue += 1
                
            }
            
        }
        
    }
    
    
    
    func stopTimerWithValidation() {
        
        guard isTimerRunning else { return }
        
        
        
        isTimerRunning = false
        
        timer?.invalidate()
        
        timer = nil
        
        
        
        let studyTime = timerValue
        
        
        
        // バックグラウンド時間チェック
        
        if backgroundTracker.backgroundTimeExceeded {
            
            validationWarning = "バックグラウンド時間が長すぎるため、今回の学習は記録されません"
            
            timerValue = 0
            
            return
            
        }
        
        
        
        // 通常通り経験値を付与
        
        timerValue = 0
        
        Task { @MainActor in
            
            let beforeLevel = self.user?.level ?? 1
            
            
            
            // 経験値を追加
            
            self.addExperience(from: studyTime)
            
            // カレンダーに記録
            
            saveTodayStudyTime(studyTime)
            
            
            
            let afterLevel = self.user?.level ?? 1
            
            let earnedExp = studyTime
            
            
            
            // ⭐️ MBTI統計更新を追加
            
            await self.updateMBTIStatistics(studyTime: studyTime)
            
            
            
            // 学習記録を保存
            
            do {
                
                try await self.saveStudyRecord(
                    
                    duration: studyTime,
                    
                    earnedExp: earnedExp,
                    
                    beforeLevel: beforeLevel,
                    
                    afterLevel: afterLevel
                    
                )
                
            } catch {
                
                print("学習記録の保存エラー: \(error)")
                
            }
            
            
            
            guard let userToSave = self.user else { return }
            
            do {
                
                try await self.saveUserData(userToSave: userToSave)
                
                validationWarning = nil
                
            } catch {
                
                self.handleError("データの保存に失敗しました", error: error)
                
            }
            
        }
        
    }
    
    
    
    
    
    func startTimer() {
        
        guard !isTimerRunning else { return }
        
        
        
        isTimerRunning = true
        
        timer?.invalidate()
        
        
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            
            Task { @MainActor in
                
                self?.timerValue += 1
                
            }
            
        }
        
    }
    
    
    
    func stopTimer() {
        
        guard isTimerRunning else { return }
        
        
        
        isTimerRunning = false
        
        timer?.invalidate()
        
        timer = nil
        
        
        
        let studyTime = timerValue
        
        timerValue = 0
        
        
        
        Task { @MainActor in
            
            self.addExperience(from: studyTime)
            
            
            
            guard let userToSave = self.user else { return }
            
            do {
                
                try await self.saveUserData(userToSave: userToSave)
                
            } catch {
                
                self.handleError("データの保存に失敗しました", error: error)
                
            }
            
        }
        
    }
    
    
    
    
    
    func forceStopTimer() {
        
        guard isTimerRunning else { return }
        
        
        
        timer?.invalidate()
        
        timer = nil
        
        isTimerRunning = false
        
        
        
        // 現在までの時間を記録
        
        let studyTime = timerValue
        
        timerValue = 0
        
        
        
        // 通常の学習記録として保存
        
        Task { @MainActor in
            
            let beforeLevel = self.user?.level ?? 1
            
            self.addExperience(from: studyTime)
            
            let afterLevel = self.user?.level ?? 1
            
            
            
            // 学習記録保存
            
            do {
                
                try await self.saveStudyRecord(
                    
                    duration: studyTime,
                    
                    earnedExp: studyTime,
                    
                    beforeLevel: beforeLevel,
                    
                    afterLevel: afterLevel
                    
                )
                
                
                
                guard let userToSave = self.user else { return }
                
                try await self.saveUserData(userToSave: userToSave)
                
            } catch {
                
                print("強制停止時の保存エラー: \(error)")
                
            }
            
        }
        
        
        
        print("タイマー強制停止: \(Int(studyTime))秒を記録")
        
    }
    
    // タイマー停止時に通知送信
    
    func stopTimerWithNotifications() {
        
        guard isTimerRunning else { return }
        
        
        
        isTimerRunning = false
        
        timer?.invalidate()
        
        timer = nil
        
        
        
        let studyTime = timerValue
        
        
        
        // バックグラウンド時間チェック
        
        if backgroundTracker.backgroundTimeExceeded {
            
            validationWarning = "バックグラウンド時間が長すぎるため、今回の学習は記録されません"
            
            timerValue = 0
            
            return
            
        }
        
        
        
        // 通常通り経験値を付与
        
        timerValue = 0
        
        Task { @MainActor in
            
            let beforeLevel = self.user?.level ?? 1
            
            
            
            // 経験値を追加
            
            self.addExperience(from: studyTime)
            
            saveTodayStudyTime(studyTime)
            
            
            
            let afterLevel = self.user?.level ?? 1
            
            let earnedExp = studyTime
            
            
            
            // MBTI統計更新
            
            await self.updateMBTIStatistics(studyTime: studyTime)
            
            
            
            // 学習記録を保存
            
            do {
                
                try await self.saveStudyRecord(
                    
                    duration: studyTime,
                    
                    earnedExp: earnedExp,
                    
                    beforeLevel: beforeLevel,
                    
                    afterLevel: afterLevel
                    
                )
                
            } catch {
                
                print("学習記録の保存エラー: \(error)")
                
            }
            
            
            
            // ⭐️ 通知送信
            
            // 学習完了通知
            
            NotificationManager.shared.sendStudyCompletedNotification(
                
                duration: studyTime,
                
                earnedExp: earnedExp
                
            )
            
            
            
            // レベルアップ通知
            
            if beforeLevel < afterLevel {
                
                NotificationManager.shared.sendLevelUpNotification(newLevel: afterLevel)
                
            }
            
            
            
            // 継続日数通知
            
            if let stats = self.studyStatistics {
                
                NotificationManager.shared.sendStreakNotification(days: stats.currentStreak)
                
            }
            
            
            
            guard let userToSave = self.user else { return }
            
            do {
                
                try await self.saveUserData(userToSave: userToSave)
                
                validationWarning = nil
                
            } catch {
                
                self.handleError("データの保存に失敗しました", error: error)
                
            }
            
        }
        
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        
        let totalHours = Int(interval) / 3600
        
        let minutes = Int(interval) / 60 % 60
        
        let seconds = Int(interval) % 60
        
        
        
        if totalHours > 0 {
            
            return String(format: "%d:%02d:%02d", totalHours, minutes, seconds)
            
        } else {
            
            return String(format: "%02d:%02d", minutes, seconds)
            
        }
        
    }
}
