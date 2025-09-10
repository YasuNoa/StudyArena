import SwiftUI
import Charts

struct MBTILearningPatternView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedAnalysisType: AnalysisType = .patterns
    @State private var learningPatterns: [String: LearningPattern] = [:]
    @State private var topPerformers: [MBTIPerformer] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    enum AnalysisType: String, CaseIterable {
        case patterns = "学習パターン"
        case timePreference = "時間帯分析"
        case consistency = "継続性分析"
        case topPerformers = "トップランカー"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                
                VStack(spacing: 0) {
                    // セグメントコントロール
                    analysisTypeSelector
                        .padding()
                    
                    if isLoading {
                        loadingView
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                switch selectedAnalysisType {
                                case .patterns:
                                    learningPatternsSection
                                case .timePreference:
                                    timePreferenceSection
                                case .consistency:
                                    consistencySection
                                case .topPerformers:
                                    topPerformersSection
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("MBTI学習分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            loadAnalysisData()
        }
    }
    
    // MARK: - セグメントコントロール
    private var analysisTypeSelector: some View {
        Picker("分析タイプ", selection: $selectedAnalysisType) {
            ForEach(AnalysisType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .colorScheme(.dark)
    }
    
    // MARK: - ローディング画面
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("学習パターンを分析中...")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 学習パターンセクション
    private var learningPatternsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "MBTI別学習パターン", icon: "brain.head.profile")
            
            if learningPatterns.isEmpty {
                EmptyPatternView(message: "学習パターンデータがありません")
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(getSortedPatterns(), id: \.key) { mbti, pattern in
                        LearningPatternCard(mbti: mbti, pattern: pattern)
                    }
                }
            }
        }
    }
    
    // MARK: - 時間帯分析セクション
    private var timePreferenceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "時間帯別学習傾向", icon: "clock.fill")
            
            // 時間帯別のヒートマップ風表示
            TimePreferenceHeatmap(patterns: learningPatterns)
            
            // 時間帯ランキング
            VStack(alignment: .leading, spacing: 15) {
                Text("時間帯別人気ランキング")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                ForEach(getTimePreferenceRanking(), id: \.hour) { item in
                    TimePreferenceRankingRow(item: item)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - 継続性分析セクション
    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "継続性分析", icon: "chart.line.uptrend.xyaxis")
            
            // 継続性スコア分布
            if #available(iOS 16.0, *) {
                ConsistencyChart(patterns: learningPatterns)
                    .frame(height: 250)
            } else {
                ConsistencyLegacyView(patterns: learningPatterns)
            }
            
            // 継続性ランキング
            VStack(alignment: .leading, spacing: 15) {
                Text("継続性ランキング")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                ForEach(getConsistencyRanking(), id: \.mbti) { item in
                    ConsistencyRankingRow(item: item)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - トップパフォーマーセクション
    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "MBTI別トップランカー", icon: "crown.fill")
            
            if topPerformers.isEmpty {
                EmptyPatternView(message: "トップランカーデータがありません")
            } else {
                VStack(spacing: 15) {
                    ForEach(Array(topPerformers.enumerated()), id: \.element.mbti) { index, performer in
                        TopPerformerCard(
                            performer: performer,
                            rank: index + 1
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - ヘルパーメソッド
    private func loadAnalysisData() {
        Task {
            isLoading = true
            
            async let patternsTask = viewModel.analyzeMBTILearningPatterns()
            async let performersTask = viewModel.getTopMBTIPerformers()
            
            let (patterns, performers) = await (patternsTask, performersTask)
            
            await MainActor.run {
                self.learningPatterns = patterns
                self.topPerformers = performers
                self.isLoading = false
            }
        }
    }
    
    private func refreshData() {
        loadAnalysisData()
    }
    
    private func getSortedPatterns() -> [(key: String, value: LearningPattern)] {
        learningPatterns.sorted { $0.value.totalSessions > $1.value.totalSessions }
    }
    
    private func getTimePreferenceRanking() -> [TimePreferenceItem] {
        var hourCounts: [Int: Int] = [:]
        
        for pattern in learningPatterns.values {
            hourCounts[pattern.preferredStudyHour, default: 0] += pattern.totalSessions
        }
        
        return hourCounts.map { TimePreferenceItem(hour: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(8)
            .map { $0 }
    }
    
    private func getConsistencyRanking() -> [ConsistencyItem] {
        learningPatterns.map { mbti, pattern in
            ConsistencyItem(
                mbti: mbti,
                consistencyScore: pattern.consistencyScore,
                rating: pattern.consistencyRating
            )
        }
        .sorted { $0.consistencyScore > $1.consistencyScore }
    }
}

// MARK: - セクションヘッダー
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - 学習パターンカード
struct LearningPatternCard: View {
    let mbti: String
    let pattern: LearningPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MBTI名
            HStack {
                Text(mbti)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                PatternInfoRow(
                    icon: "clock.fill",
                    title: "平均セッション",
                    value: pattern.formattedAverageSession,
                    color: .green
                )
                
                PatternInfoRow(
                    icon: "sun.max.fill",
                    title: "好む時間帯",
                    value: pattern.formattedPreferredTime,
                    color: .orange
                )
                
                PatternInfoRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "継続性",
                    value: pattern.consistencyRating,
                    color: .purple
                )
                
                PatternInfoRow(
                    icon: "number",
                    title: "総セッション",
                    value: "\(pattern.totalSessions)回",
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(getMBTIColor(mbti).opacity(0.3), lineWidth: 1)
                )
        )
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

// MARK: - パターン情報行
struct PatternInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

// MARK: - 時間帯ヒートマップ
struct TimePreferenceHeatmap: View {
    let patterns: [String: LearningPattern]
    
    private var heatmapData: [(hour: Int, intensity: Double)] {
        var hourCounts: [Int: Int] = [:]
        
        for pattern in patterns.values {
            hourCounts[pattern.preferredStudyHour, default: 0] += pattern.totalSessions
        }
        
        let maxCount = hourCounts.values.max() ?? 1
        
        return (0...23).map { hour in
            let count = hourCounts[hour] ?? 0
            let intensity = Double(count) / Double(maxCount)
            return (hour: hour, intensity: intensity)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("24時間学習活動ヒートマップ")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 8), spacing: 2) {
                ForEach(heatmapData, id: \.hour) { data in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.2 + data.intensity * 0.8))
                        .frame(height: 30)
                        .overlay(
                            Text("\(data.hour)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                }
            }
            
            // 凡例
            HStack {
                Text("少ない")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.2 + Double(index) * 0.2))
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text("多い")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 継続性チャート（iOS 16以上）
@available(iOS 16.0, *)
struct ConsistencyChart: View {
    let patterns: [String: LearningPattern]
    
    private var chartData: [(mbti: String, score: Double)] {
        patterns.map { (mbti: $0.key, score: $0.value.consistencyScore) }
            .sorted { $0.score > $1.score }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("継続性スコア分布")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Chart(chartData, id: \.mbti) { item in
                BarMark(
                    x: .value("MBTI", item.mbti),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(getConsistencyColor(item.score).gradient)
                .cornerRadius(8)
            }
            .chartXAxis {
                AxisMarks(values: chartData.map { $0.mbti }) { value in
                    AxisValueLabel {
                        if let mbti = value.as(String.self) {
                            Text(mbti)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]) { value in
                    AxisValueLabel {
                        if let score = value.as(Double.self) {
                            Text(String(format: "%.1f", score))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func getConsistencyColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .yellow
        case 0.2..<0.4: return .orange
        default: return .red
        }
    }
}

// MARK: - 継続性レガシービュー
struct ConsistencyLegacyView: View {
    let patterns: [String: LearningPattern]
    
    private var sortedData: [(mbti: String, score: Double)] {
        patterns.map { (mbti: $0.key, score: $0.value.consistencyScore) }
            .sorted { $0.score > $1.score }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("継続性スコア")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 8) {
                ForEach(sortedData, id: \.mbti) { item in
                    HStack {
                        Text(item.mbti)
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 50, alignment: .leading)
                        
                        GeometryReader { geometry in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(getConsistencyColor(item.score).gradient)
                                    .frame(width: geometry.size.width * CGFloat(item.score))
                                    .animation(.spring(), value: item.score)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 20)
                        
                        Text(String(format: "%.2f", item.score))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func getConsistencyColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .yellow
        case 0.2..<0.4: return .orange
        default: return .red
        }
    }
}

// MARK: - トップパフォーマーカード
struct TopPerformerCard: View {
    let performer: MBTIPerformer
    let rank: Int
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.7)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .white.opacity(0.7)
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2, 3: return "medal.fill"
        default: return "number.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // ランクアイコン
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 2) {
                    Image(systemName: rankIcon)
                        .font(.title3)
                        .foregroundColor(rankColor)
                    
                    if rank > 3 {
                        Text("\(rank)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(rankColor)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(performer.mbti)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Lv.\(performer.level)")
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.2))
                        )
                }
                
                Text(performer.nickname)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("総学習時間: \(performer.formattedStudyTime)")
                    .font(.caption)
                    .foregroundColor(.green.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(rankColor.opacity(0.3), lineWidth: rank <= 3 ? 2 : 1)
                )
        )
    }
}

// MARK: - その他のコンポーネント
struct EmptyPatternView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text(message)
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}

struct TimePreferenceRankingRow: View {
    let item: TimePreferenceItem
    
    var body: some View {
        HStack {
            Text(String(format: "%02d:00", item.hour))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 50)
            
            Text("\(item.count)セッション")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
}

struct ConsistencyRankingRow: View {
    let item: ConsistencyItem
    
    var body: some View {
        HStack {
            Text(item.mbti)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 50)
            
            Text(item.rating)
                .font(.caption)
                .foregroundColor(getConsistencyColor(item.consistencyScore))
            
            Spacer()
            
            Text(String(format: "%.2f", item.consistencyScore))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private func getConsistencyColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .yellow
        case 0.2..<0.4: return .orange
        default: return .red
        }
    }
}

// MARK: - データ構造体
struct TimePreferenceItem {
    let hour: Int
    let count: Int
}

struct ConsistencyItem {
    let mbti: String
    let consistencyScore: Double
    let rating: String
}