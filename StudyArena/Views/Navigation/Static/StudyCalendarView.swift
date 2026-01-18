//
//  StudyCalendarView.swift
//  StudyArena
//
//  Created by 田中正造 on 22/08/2025.
//


import SwiftUI

struct StudyCalendarView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var studyRecordViewModel = StudyRecordViewModel()
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Date.jstCalendar
    private let dateFormatter: DateFormatter = {
        let formatter = Date.jstFormatter
        formatter.dateFormat = "yyyy年MM月"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            MinimalDarkBackgroundView()
            
            VStack(spacing: 0) {
                // 月表示ヘッダー
                CalendarHeader(currentMonth: $currentMonth)
                    .padding()
                
                // カレンダーグリッド
                CalendarGrid(
                    currentMonth: currentMonth,
                    selectedDate: $selectedDate,
                    studyData: studyRecordViewModel.dailyStudyData
                )
                .padding(.horizontal)
                
                // 選択日の詳細
                DayDetailView(
                    date: selectedDate,
                    studyTime: getStudyTime(for: selectedDate)
                )
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            // ユーザーID同期
            studyRecordViewModel.userId = viewModel.user?.id
            
            Task {
                studyRecordViewModel.loadMonthlyData(for: currentMonth)
            }
        }
        .onChange(of: currentMonth) { newMonth in
            Task {
                studyRecordViewModel.loadMonthlyData(for: newMonth)
            }
        }
    }
    
    private func getStudyTime(for date: Date) -> TimeInterval {
        let day = calendar.startOfDay(for: date)
        return studyRecordViewModel.dailyStudyData[day] ?? 0
    }
}

// カレンダーグリッド
struct CalendarGrid: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    let studyData: [Date: TimeInterval]
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        VStack(spacing: 10) {
            // 曜日ヘッダー
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日付グリッド
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: isSameDay(date, selectedDate),
                            studyTime: studyData[date] ?? 0
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 45)
                    }
                }
            }
        }
    }
    
    // 各日のセル
    struct DayCell: View {
        let date: Date
        let isSelected: Bool
        let studyTime: TimeInterval
        let action: () -> Void
        
        private var isToday: Bool {
            Date.jstCalendar.isDateInToday(date)
        }
        
        private var studyIntensity: Double {
            min(1.0, studyTime / 14400) // 4時間を最大とする
        }
        
        var body: some View {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isSelected ? Color.blue.opacity(0.3) :
                            studyTime > 0 ? Color.green.opacity(0.1 + studyIntensity * 0.4) :
                            Color.white.opacity(0.05)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isToday ? Color.blue :
                                    isSelected ? Color.blue.opacity(0.5) :
                                    Color.white.opacity(0.1),
                                    lineWidth: isToday ? 2 : 1
                                )
                        )
                    
                    VStack(spacing: 2) {
                        Text("\(Date.jstCalendar.component(.day, from: date))")
                            .font(.system(size: 16, weight: isToday ? .bold : .medium))
                            .foregroundColor(.white)
                        
                        if studyTime > 0 {
                            Text(formatShortTime(studyTime))
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                        }
                    }
                }
                .frame(height: 45)
            }
        }
        
        private func formatShortTime(_ time: TimeInterval) -> String {
            let hours = Int(time) / 3600
            let minutes = Int(time) / 60 % 60
            if hours > 0 {
                return "\(hours)h"
            } else {
                return "\(minutes)m"
            }
        }
    }
    
    // 月の日付を取得
    private func getDaysInMonth() -> [Date?] {
        let calendar = Date.jstCalendar
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)!.start
        let numberOfDays = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Date.jstCalendar.isDate(date1, inSameDayAs: date2)
    }
}

// カレンダーヘッダー
struct CalendarHeader: View {
    @Binding var currentMonth: Date
    
    private let dateFormatter: DateFormatter = {
        let formatter = Date.jstFormatter
        formatter.dateFormat = "yyyy年MM月"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: currentMonth))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private func previousMonth() {
        currentMonth = Date.jstCalendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = Date.jstCalendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

// 選択日の詳細表示
struct DayDetailView: View {
    let date: Date
    let studyTime: TimeInterval
    
    private let dateFormatter: DateFormatter = {
        let formatter = Date.jstFormatter
        formatter.dateFormat = "MM月dd日(E)"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateFormatter.string(from: date))
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.green)
                
                Text(formatStudyTime(studyTime))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            if studyTime > 0 {
                ProgressView(value: min(1.0, studyTime / 14400))
                    .tint(.green)
                Text("目標: 4時間")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            } else {
                Text("この日はまだ学習記録がありません")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func formatStudyTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}
