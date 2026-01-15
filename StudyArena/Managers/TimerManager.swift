// TimerManager.swift
import Foundation
import Combine
    //managerはreturnをつけず計算結果をreturnするだけのことが多いらしい。

class TimerManager: ObservableObject {
    @Published var timerValue: TimeInterval = 0
    @Published var isTimerRunning: Bool = false
    @Published var backgroundTracker = BackgroundTracker()
    @Published var validationWarning: String?
    
    static let shared = TimerManager()
    //（クロージャー）を用意しておく
    // (Double)を受け取って、何も返さない(Void)関数が入る箱
    var onUpdate: ((Double) -> Void)?
    
    private var timer: Timer?
    
    // 完了報告用Combine Subject
    let timerCompletedSubject = PassthroughSubject<TimeInterval, Never>()
    
    
    func startTimer() {
        guard !isTimerRunning else { return }
        
        backgroundTracker.resetSession()
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
        
        // バックグラウンド時間チェック
        if backgroundTracker.backgroundTimeExceeded {
            validationWarning = "バックグラウンド時間が長すぎるため、記録されません"
            return
        }
        
        // 完了報告（Combineで通知）
        timerCompletedSubject.send(studyTime)
    }
    
    func forceStop() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        timerValue = 0
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
    
    deinit {
        timer?.invalidate()
        print("🗑️ TimerManager Deinitialized")
    }
}
