import SwiftUI
import Charts

struct StudyStatisticsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedPeriod: Period = .week
    @State private var isLoading = true
    
    enum Period: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        case all = "全期間"
    }
    
    var body: some View {
        ZStack {
            MinimalDarkBackgroundView()
            
            VStack(spacing: 0) {
                // ヘッダー
                headerSection
                
                if isLoading {
                    loadingSection
                } else if viewModel.studyRecords.isEmpty {
                    emptyStateSection
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            // 統計サマリー
                            if let stats = viewModel.studyStatistics {
                                statisticsSummary(stats: stats)
                            }
                            
                            // 期間選択
                            periodSelector
                            
                            // グラフセクション
                            if #available(iOS 16.0, *) {
                                modernChartSection
                            } else {
                                legacyChartSection
                            }
                            
                            // 学習記録リスト
                            recentRecordsSection
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - ヘッダー
    private var headerSection: some View {
        Text("学習統計")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top)
    }
    
    // MARK: - ローディング
    private var loadingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("データを読み込み中...")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 空状態
    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("学習記録がありません")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            
            Text("タイマーで学習を始めましょう")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 統計サマリー
    private func statisticsSummary(stats: StudyStatistics) -> some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                StatCard(
                    title: "連続日数",
                    value: "\(stats.currentStreak)日",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "総学習日数",
                    value: "\(stats.totalStudyDays)日",
                    icon: "calendar",
                    color: .blue
                )
            }
            
            HStack(spacing: 15) {
                StatCard(
                    title: "平均学習時間",
                    value: stats.formattedAverageTime,
                    icon: "clock.fill",
                    color: .green
                )
                
                StatCard(
                    title: "総記録数",
                    value: "\(stats.totalRecords)回",
                    icon: "doc.text.fill",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - 期間選択
    private var periodSelector: some View {
        Picker("期間", selection: $selectedPeriod) {
            ForEach(Period.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .colorScheme(.dark)
    }
    
    // MARK: - iOS 16以上用のチャート（修正版）
    @available(iOS 16.0, *)
    private var modernChartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学習時間の推移")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Chart(getChartData()) { item in
                BarMark(
                    x: .value("日付", item.date, unit: .day),
                    y: .value("時間", item.hours)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel {
                        // 🔧 修正: valueを正しくDate型として扱う
                        if let date = value.as(Date.self) {
                            Text(formatAxisDate(date))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        // 🔧 修正: valueを正しくDouble型として扱う
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - iOS 16未満用のレガシーチャート
    private var legacyChartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学習時間の推移")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 10) {
                ForEach(getChartData().suffix(7), id: \.date) { item in
                    HStack {
                        Text(formatAxisDate(item.date))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 60, alignment: .leading)
                        
                        GeometryReader { geometry in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(item.hours) / 8.0)
                                    .animation(.spring(), value: item.hours)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 20)
                        
                        Text("\(item.hours)h")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 最近の記録
    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最近の学習記録")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 10) {
                ForEach(viewModel.studyRecords.prefix(5)) { record in
                    RecordRow(record: record)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - ヘルパーメソッド
    private func loadData() {
        isLoading = true
        viewModel.loadStudyRecords()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
    
    private func getChartData() -> [ChartDataItem] {
        // 期間に応じてデータをフィルタリング
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        // 日付ごとにグループ化
        let filteredRecords = viewModel.studyRecords.filter { record in
            record.timestamp >= startDate && record.recordType == .study
        }
        
        let grouped = Dictionary(grouping: filteredRecords) { record in
            calendar.startOfDay(for: record.timestamp)
        }
        
        return grouped.map { date, records in
            let totalHours = records.reduce(0) { $0 + $1.duration } / 3600
            return ChartDataItem(date: date, hours: Int(totalHours))
        }.sorted { $0.date < $1.date }
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - サポート構造体
struct ChartDataItem: Identifiable {
    var id: Date { date }
    let date: Date
    let hours: Int
}

struct RecordRow: View {
    let record: StudyRecord
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(record.recordType.color))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(record.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(record.formattedDuration)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// StatCardは既存のものを使用するか、ここで定義
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
#Preview {
    StudyStatisticsView()
        .environmentObject(MainViewModel.mock)
}
#endif
