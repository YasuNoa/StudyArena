import SwiftUI

// StudyRecordとTimelinePostを統合して表示
struct TimelineView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var studyRecordViewModel = StudyRecordViewModel()
    @StateObject private var timelineViewModel = TimelineViewModel()
    @State private var selectedFilter: FilterType = .all
    @State private var showPostCreate = false
    
    enum FilterType: String, CaseIterable {
        case all = "すべて"
        case study = "学習"
        case posts = "投稿"
        case levelUp = "レベルアップ"
    }
    

    // 統合されたタイムラインアイテム
    var timelineItems: [TimelineItemType] {
        var items: [TimelineItemType] = []
        
        // フィルターに応じてアイテムを追加
        switch selectedFilter {
        case .all:
            items = studyRecordViewModel.studyRecords.map { .studyRecord($0) }
            items += timelineViewModel.timelinePosts.map { .post($0) }
        case .study:
            items = studyRecordViewModel.studyRecords
                .filter { $0.recordType == .study }
                .map { .studyRecord($0) }
        case .posts:
            items = timelineViewModel.timelinePosts.map { .post($0) }
        case .levelUp:
            items = studyRecordViewModel.studyRecords
                .filter { $0.recordType == .levelUp }
                .map { .studyRecord($0) }
        }
        
        // タイムスタンプでソート
        return items.sorted { item1, item2 in
            let date1 = getTimestamp(from: item1)
            let date2 = getTimestamp(from: item2)
            return date1 > date2
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 15) {
                    if let stats = studyRecordViewModel.studyStatistics {
                        StudyStatsCard(statistics: stats)
                    }
                    
                    // フィルター
                    FilterSegmentedControl(selectedFilter: $selectedFilter)
                }
                .padding(.top, 50)
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                 if timelineItems.isEmpty {
                     EmptyTimelineView()
                 } else {
                     ScrollView {
                         LazyVStack(spacing: 12) {
                             ForEach(Array(timelineItems.enumerated()), id: \.offset) { _, item in
                                 Group {
                                     switch item {
                                     case .studyRecord(let record):
                                         TimelineCard(record: record)
                                     case .post(let post):
                                         TimelinePostCard(post: post)
                                     }
                                 }
                                .padding(.horizontal)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                             }
                         }
                         .padding(.vertical, 10)
                         .padding(.bottom, 100)
                     }
                     .refreshable {
                         studyRecordViewModel.loadRecords()
                         timelineViewModel.loadTimelinePosts()
                     }
                 }
                 Spacer()
            }
            // ⭐️ プラスボタン（右下）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showPostCreate = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: .blue.opacity(0.4), radius: 10)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100) // TabBarの上に配置
                }
            }
        }
        .environmentObject(timelineViewModel) // Inject here
        .onAppear {
            // Sync User
            studyRecordViewModel.userId = viewModel.user?.id
            timelineViewModel.userId = viewModel.user?.id
            timelineViewModel.user = viewModel.user

            studyRecordViewModel.loadRecords()
            timelineViewModel.loadTimelinePosts() 
        }
        .sheet(isPresented: $showPostCreate) {
            PostCreateView(isPresented: $showPostCreate)
                .environmentObject(viewModel)
                .environmentObject(timelineViewModel)
        }
    }
    
    private func getTimestamp(from item: TimelineItemType) -> Date {
        switch item {
        case .studyRecord(let record):
            return record.timestamp
        case .post(let post):
            return post.timestamp
        }
    }
}

// 統計情報カード
struct StudyStatsCard: View {
    let statistics: StudyStatistics
    
    var body: some View {
        HStack(spacing: 20) {
            TimelineStatItem(
                icon: "flame.fill",
                value: "\(statistics.currentStreak)",
                label: "連続日数",
                color: .orange
            )
            
            TimelineStatItem(
                icon: "calendar",
                value: "\(statistics.totalStudyDays)",
                label: "総学習日数",
                color: .blue
            )
            
            TimelineStatItem(
                icon: "clock.fill",
                value: statistics.formattedAverageTime,
                label: "平均時間",
                color: .green
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct TimelineStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.5), radius: 5)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// フィルターセグメント
struct FilterSegmentedControl: View {
    @Binding var selectedFilter: TimelineView.FilterType
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimelineView.FilterType.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = filter
                    }
                }) {
                    Text(filter.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.6))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Group {
                                if selectedFilter == filter {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.3))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                        )
                                        .matchedGeometryEffect(id: "filter", in: animation)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// タイムラインカード（学習記録）
struct TimelineCard: View {
    let record: StudyRecord
    @State private var isAnimated = false
    
    var body: some View {
        HStack(spacing: 15) {
            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(record.recordType.color).opacity(0.3),
                                Color(record.recordType.color).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .scaleEffect(isAnimated ? 1 : 0.8)
                    .opacity(isAnimated ? 1 : 0)
                
                Image(systemName: record.recordType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(record.recordType.color))
                    .scaleEffect(isAnimated ? 1 : 0.5)
                    .rotationEffect(.degrees(record.recordType == .levelUp && isAnimated ? 360 : 0))
            }
            
            // コンテンツ
            VStack(alignment: .leading, spacing: 6) {
                Text(record.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(record.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(record.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // 経験値表示（学習記録の場合）
            if record.recordType == .study {
                VStack {
                    Text("+\(Int(record.earnedExperience))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                    Text("EXP")
                        .font(.system(size: 10))
                        .foregroundColor(.green.opacity(0.7))
                }
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 10)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            record.recordType == .levelUp ?
                            LinearGradient(
                                colors: [.yellow.opacity(0.5), .orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : LinearGradient(
                                colors: [Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: record.recordType == .levelUp ? 2 : 1
                        )
                )
                .shadow(
                    color: record.recordType == .levelUp ?
                    Color.yellow.opacity(0.2) : Color.clear,
                    radius: 10
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                isAnimated = true
            }
        }
    }
}


import SwiftUI

struct TimelinePostCard: View {
    let post: TimelinePost
    @EnvironmentObject var timelineViewModel: TimelineViewModel
    @State private var isAnimated = false
    @State private var isLiking = false
    @State private var localLikeCount: Int
    @State private var isLiked: Bool
    
    init(post: TimelinePost) {
        self.post = post
        self._localLikeCount = State(initialValue: post.likeCount ?? 0)
        self._isLiked = State(initialValue: false)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ユーザー情報
            HStack(spacing: 12) {
                // アバター
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("StudyGreen"), Color("StudyMint")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.nickname.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.nickname)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text("Lv.\(post.level)")
                            .font(.caption)
                            .foregroundColor(Color("StudyGreen"))
                        
                        // 学習時間を表示
                        if let duration = post.studyDuration {
                            Text("・")
                                .foregroundColor(.white.opacity(0.3))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 10))
                                Text(formatStudyTime(duration))
                            }
                            .font(.caption)
                            .foregroundColor(Color("StudyBlue").opacity(0.8))
                        }
                        
                        Text("・")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text(post.relativeTime)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // 投稿アイコン
                Image(systemName: "bubble.left.fill")
                    .font(.caption)
                    .foregroundColor(Color("StudyGreen").opacity(0.5))
            }
            
            // 投稿内容
            Text(post.content)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
            
            // いいねエリア
            HStack {
                Spacer()
                
                Button(action: toggleLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(isLiked ? Color("StudyRed") : .white.opacity(0.6))
                            .scaleEffect(isLiking ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLiking)
                        
                        if localLikeCount > 0 {
                            Text("\(localLikeCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isLiked ? Color("StudyRed").opacity(0.3) : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .disabled(isLiking)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            LinearGradient(
                                colors: [Color("StudyGreen").opacity(0.3), Color("StudyMint").opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isAnimated ? 1 : 0.95)
        .opacity(isAnimated ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4)) {
                isAnimated = true
            }
            
            // いいね状態を確認
            loadLikeStatus()
        }
    }
    
    private func toggleLike() {
        guard !isLiking, let postId = post.id else { return }
        
        isLiking = true
        
        // アニメーション
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isLiked.toggle()
            localLikeCount += isLiked ? 1 : -1
        }
        
        // ⭐️ TimelineViewModelの実装済みメソッドを使用
        Task {
            do {
                let result = try await timelineViewModel.toggleLike(for: postId)
                
                await MainActor.run {
                    // サーバーの結果で更新
                    isLiked = result.isLiked
                    localLikeCount = result.newCount
                    isLiking = false
                }
            } catch {
                // エラー時は元に戻す
                await MainActor.run {
                    withAnimation {
                        isLiked.toggle()
                        localLikeCount += isLiked ? 1 : -1
                    }
                    isLiking = false
                }
                print("いいね保存エラー: \(error)")
            }
        }
    }
    
    private func loadLikeStatus() {
        guard let postId = post.id else { return }
        
        Task {
            let liked = timelineViewModel.isPostLikedByUser(post)
            await MainActor.run {
                isLiked = liked
            }
        }
    }
    
    private func formatStudyTime(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分学習"
        } else {
            return "\(minutes)分学習"
        }
    }
}

// 空のタイムライン表示
struct EmptyTimelineView: View {
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.2))
                .rotationEffect(.degrees(isAnimated ? 360 : 0))
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimated)
            
            Text("まだ記録がありません")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.6))
            
            Text("学習を始めてタイムラインを作りましょう")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxHeight: .infinity)
        .onAppear {
            isAnimated = true
        }
    }
}

#if DEBUG
#Preview {
    TimelineView()
        .environmentObject(MainViewModel.mock)
}
#endif
