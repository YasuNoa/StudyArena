import SwiftUI
import Charts // iOS 16以上で利用可能

struct MBTIStatsView: View {
    // 🔧 修正: MainViewModelではなくMBTIViewModelを使用
    @StateObject private var viewModel = MBTIViewModel()
    @State private var selectedMBTI: String? = nil
    @State private var showMBTISelector = false
    @State private var selectedMetric: MetricType = .studyTime
    @State private var isLoading = true
    
    enum MetricType: String, CaseIterable {
        case studyTime = "学習時間"
        // ユーザー数や平均時間はデータがないため一旦削除、または将来用に残すならstudyTimeのみ有効可
        // Simplificationのため学習時間のみにする
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
                            // メトリクス選択 (今は学習時間のみなので非表示でも良いが、拡張性のため残すか、タイトルとして表示)
                            // metricSelectorSection
                            
                            // 円グラフセクション
                            chartSection
                            
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
    
    // MARK: - チャートセクション
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("MBTI分布 (学習時間)")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            if #available(iOS 16.0, *) {
                MBTIPieChart(
                    statistics: viewModel.mbtiStatistics,
                    metric: .studyTime
                )
                .frame(height: 300)
            } else {
                // iOS 16未満の場合のフォールバック
                MBTILegacyChart(
                    statistics: viewModel.mbtiStatistics,
                    metric: .studyTime
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
                        isMyType: false // 簡易版のため一旦false, 必要ならUserServiceから取得
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
        // ViewModel側でloadData呼出し
        viewModel.loadData()
        // Loading状態の同期はViewModelのPublishを監視すれば自動で行われるが、
        // ここではローカルのisLoadingと同期させるか、ViewModelのisLoadingを使うようにViewを修正すべき
        // 一旦簡易的に
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
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
            let value = stat.totalTime
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
                VStack {
                    Text("合計")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(formatTotalValue())
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
        let hours = Int(total) / 3600
        return "\(hours)時間"
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

// MARK: - iOS 16未満用のレガシーチャート
struct MBTILegacyChart: View {
    let statistics: [String: MBTIStatData]
    let metric: MBTIStatsView.MetricType
    
    private var chartData: [(String, Double, Color)] {
        statistics.compactMap { key, stat in
            let value = stat.totalTime
            let color = getMBTIColor(key)
            return (key, value, color)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack {
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
        }
    }
    
    private func getPercentage(for value: Double) -> CGFloat {
        let maxValue = chartData.max { $0.1 < $1.1 }?.1 ?? 1
        return CGFloat(value / maxValue)
    }
    
    private func formatValue(_ value: Double) -> String {
        let hours = Int(value) / 3600
        return "\(hours)h"
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
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 30)
            
            Text(mbtiStat.mbtiType)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isMyType ? .yellow : .white)
                .frame(width: 50)
            
            Spacer()
            
            Text(formatTime(mbtiStat.totalTime))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
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
        let minutes = Int(seconds) % 3600 / 60
        return "\(hours)時間 \(minutes)分"
    }
}
