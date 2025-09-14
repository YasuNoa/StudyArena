import SwiftUI
import Charts // iOS 16以上で利用可能

struct MBTIStatsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedMBTI: String? = nil
    @State private var showMBTISelector = false
    @State private var selectedMetric: MetricType = .studyTime
    @State private var isLoading = true
    
    enum MetricType: String, CaseIterable {
        case studyTime = "学習時間"
        case userCount = "ユーザー数"
        case averageTime = "平均時間"
    }
    
    var body: some View {
        ZStack {
            MinimalDarkBackgroundView()
            
            VStack(spacing: 0) {
                // ヘッダー
                headerSection
                
                if isLoading {
                    loadingSection
                } else if viewModel.mbtiStatistics.isEmpty {
                    emptyStateSection
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            // 自分のMBTI情報
                            if let myMBTI = viewModel.user?.mbtiType {
                                myMBTISection(mbti: myMBTI)
                            } else {
                                mbtiSetupSection
                            }
                            
                            // メトリクス選択
                            metricSelectorSection
                            
                            // 円グラフセクション
                            chartSection
                            
                            // 詳細統計
                            detailsSection
                            
                            // ランキング
                            rankingSection
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            loadStatistics()
        }
        .sheet(isPresented: $showMBTISelector) {
            MBTISelectionView(selectedMBTI: $selectedMBTI)
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - ヘッダーセクション
    private var headerSection: some View {
        Text("MBTI別 学習統計")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top)
    }
    
    // MARK: - ローディングセクション
    private var loadingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("統計データを読み込み中...")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 空状態セクション
    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("統計データがありません")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            
            Text("まだ十分なデータが蓄積されていません")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 自分のMBTIセクション
    private func myMBTISection(mbti: String) -> some View {
        let stats = viewModel.mbtiStatistics[mbti]
        
        return VStack(spacing: 15) {
            HStack {
                Text("あなたのMBTI")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Button("変更") {
                    showMBTISelector = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 20) {
                // MBTI表示
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text(mbti)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // 統計情報
                VStack(alignment: .leading, spacing: 8) {
                    if let stats = stats {
                        // 🔧 修正: StatRowをMBTIStatRowに名前変更してコンフリクト回避
                        MBTIStatRow(
                            title: "総学習時間",
                            value: formatTime(stats.totalTime),
                            color: .green
                        )
                        MBTIStatRow(
                            title: "平均時間/日",
                            value: formatTime(stats.avgTime),
                            color: .blue
                        )
                        MBTIStatRow(
                            title: "同タイプユーザー",
                            value: "\(stats.userCount)人",
                            color: .purple
                        )
                    } else {
                        Text("データ収集中...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - MBTI設定セクション
    private var mbtiSetupSection: some View {
        Button(action: { showMBTISelector = true }) {
            VStack(spacing: 15) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
                
                Text("MBTIタイプを設定")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("統計情報を表示するため、あなたのMBTIタイプを設定してください")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.purple.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - メトリクス選択セクション
    private var metricSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("表示項目")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 10) {
                ForEach(MetricType.allCases, id: \.self) { metric in
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedMetric = metric
                        }
                    }) {
                        Text(metric.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedMetric == metric ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedMetric == metric ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedMetric == metric ? Color.blue : Color.white.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - チャートセクション
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("MBTI分布")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            if #available(iOS 16.0, *) {
                MBTIPieChart(
                    statistics: viewModel.mbtiStatistics,
                    metric: selectedMetric
                )
                .frame(height: 300)
            } else {
                // iOS 16未満の場合のフォールバック
                MBTILegacyChart(
                    statistics: viewModel.mbtiStatistics,
                    metric: selectedMetric
                )
                .frame(height: 300)
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
    
    // MARK: - 詳細セクション
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("詳細統計")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                MBTIStatCard(
                    title: "総ユーザー数",
                    value: "\(getTotalUsers())人",
                    icon: "person.3.fill",
                    color: .blue
                )
                
                MBTIStatCard(
                    title: "総学習時間",
                    value: formatTime(getTotalStudyTime()),
                    icon: "clock.fill",
                    color: .green
                )
                
                MBTIStatCard(
                    title: "平均学習時間",
                    value: formatTime(getAverageStudyTime()),
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                MBTIStatCard(
                    title: "最も多いタイプ",
                    value: getMostPopularMBTI(),
                    icon: "crown.fill",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - ランキングセクション
    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学習時間ランキング")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 10) {
                ForEach(getSortedMBTIStats(), id: \.mbtiType) { stat in
                    MBTIRankingRow(
                        mbtiStat: stat,
                        rank: getRank(for: stat),
                        isMyType: stat.mbtiType == viewModel.user?.mbtiType
                    )
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
    
    // MARK: - Private Methods
    private func loadStatistics() {
        Task {
            isLoading = true
            await viewModel.loadMBTIStatistics()
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        
        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "\(days)日\(remainingHours)時間"
        } else if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    private func getTotalUsers() -> Int {
        viewModel.mbtiStatistics.values.reduce(0) { $0 + $1.userCount }
    }
    
    private func getTotalStudyTime() -> Double {
        viewModel.mbtiStatistics.values.reduce(0) { $0 + $1.totalTime }
    }
    
    private func getAverageStudyTime() -> Double {
        let totalUsers = getTotalUsers()
        guard totalUsers > 0 else { return 0 }
        return getTotalStudyTime() / Double(totalUsers)
    }
    
    private func getMostPopularMBTI() -> String {
        guard let mostPopular = viewModel.mbtiStatistics.max(by: { $0.value.userCount < $1.value.userCount }) else {
            return "N/A"
        }
        return mostPopular.key
    }
    
    private func getSortedMBTIStats() -> [MBTIStatData] {
        viewModel.mbtiStatistics.values.sorted { $0.totalTime > $1.totalTime }
    }
    
    private func getRank(for stat: MBTIStatData) -> Int {
        let sorted = getSortedMBTIStats()
        return (sorted.firstIndex { $0.mbtiType == stat.mbtiType } ?? 0) + 1
    }
}

// MARK: - iOS 16以上用の円グラフ
@available(iOS 16.0, *)
struct MBTIPieChart: View {
    let statistics: [String: MBTIStatData]
    let metric: MBTIStatsView.MetricType
    
    private var chartData: [(String, Double, Color)] {
        statistics.compactMap { key, stat in
            let value: Double
            switch metric {
            case .studyTime:
                value = stat.totalTime
            case .userCount:
                value = Double(stat.userCount)
            case .averageTime:
                value = stat.avgTime
            }
            
            let color = getMBTIColor(key)
            return (key, value, color)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack {
            Chart(chartData, id: \.0) { item in
                SectorMark(
                    angle: .value("Value", item.1),
                    innerRadius: .ratio(0.4),
                    angularInset: 2
                )
                .foregroundStyle(item.2.gradient)
                .cornerRadius(8)
            }
            .chartBackground { _ in
                // 中央のテキスト
                VStack {
                    Text(metric.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("合計: \(formatTotalValue())")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // 凡例
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(chartData, id: \.0) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.2)
                            .frame(width: 8, height: 8)
                        
                        Text(item.0)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }
    
    private func formatTotalValue() -> String {
        let total = chartData.reduce(0) { $0 + $1.1 }
        switch metric {
        case .studyTime, .averageTime:
            let hours = Int(total) / 3600
            return "\(hours)時間"
        case .userCount:
            return "\(Int(total))人"
        }
    }
    
    private func getMBTIColor(_ mbti: String) -> Color {
        // MBTIタイプに基づいた色分け
        switch mbti.prefix(2) {
        case "NT": return .blue
        case "NF": return .green
        case "ST": return .orange
        case "SF": return .purple
        default: return .gray
        }
    }
}

// MARK: - iOS 16未満用のレガシーチャート
struct MBTILegacyChart: View {
    let statistics: [String: MBTIStatData]
    let metric: MBTIStatsView.MetricType
    
    private var chartData: [(String, Double, Color)] {
        statistics.compactMap { key, stat in
            let value: Double
            switch metric {
            case .studyTime:
                value = stat.totalTime
            case .userCount:
                value = Double(stat.userCount)
            case .averageTime:
                value = stat.avgTime
            }
            
            let color = getMBTIColor(key)
            return (key, value, color)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack {
            // 簡易的な棒グラフ
            VStack(alignment: .leading, spacing: 8) {
                ForEach(chartData.prefix(8), id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 50, alignment: .leading)
                        
                        GeometryReader { geometry in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.2.gradient)
                                    .frame(width: geometry.size.width * getPercentage(for: item.1))
                                    .animation(.spring(), value: item.1)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 20)
                        
                        Text(formatValue(item.1))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
            
            Text("※ iOS 16以上で円グラフ表示可能")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .padding(.top)
        }
    }
    
    private func getPercentage(for value: Double) -> CGFloat {
        let maxValue = chartData.max { $0.1 < $1.1 }?.1 ?? 1
        return CGFloat(value / maxValue)
    }
    
    private func formatValue(_ value: Double) -> String {
        switch metric {
        case .studyTime, .averageTime:
            let hours = Int(value) / 3600
            return "\(hours)h"
        case .userCount:
            return "\(Int(value))人"
        }
    }
    
    private func getMBTIColor(_ mbti: String) -> Color {
        switch mbti.prefix(2) {
        case "NT": return .blue
        case "NF": return .green
        case "ST": return .orange
        case "SF": return .purple
        default: return .gray
        }
    }
}

// MARK: - 統計カード
struct  MBTIStatCard: View {
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

// MARK: - MBTIランキング行
struct MBTIRankingRow: View {
    let mbtiStat: MBTIStatData
    let rank: Int
    let isMyType: Bool
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.7)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .white.opacity(0.7)
        }
    }
    
    var body: some View {
        HStack {
            // ランク
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 30)
            
            // MBTI
            Text(mbtiStat.mbtiType)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isMyType ? .yellow : .white)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("総学習時間:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(formatTime(mbtiStat.totalTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("ユーザー数:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(mbtiStat.userCount)人")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("平均")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                
                Text(formatTime(mbtiStat.avgTime))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isMyType ? Color.yellow.opacity(0.1) : Color.white.opacity(0.05))
        )
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        if hours > 24 {
            let days = hours / 24
            return "\(days)日"
        } else if hours > 0 {
            return "\(hours)時間"
        } else {
            let minutes = Int(seconds) / 60
            return "\(minutes)分"
        }
    }
}

// MARK: - 🔧 修正：StatRowをMBTIStatRowに名前変更してコンフリクト回避
struct MBTIStatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}
