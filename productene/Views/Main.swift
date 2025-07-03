// FileName: ContentView.swift

import SwiftUI

// MARK: - Main Content View with TabBar
struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(errorMessage: errorMessage) {
                    // リトライ機能
                    viewModel.retryAuthentication()
                }
            } else {
                MainTabView()
                    .environmentObject(viewModel)
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("データを読み込み中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error View
struct ErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("エラーが発生しました")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(errorMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            Button("再試行") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("タイマー")
                }
            
            RankingView()
                .tabItem {
                    Image(systemName: "list.number")
                    Text("ランキング")
                }
            
            HeroSelectionView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("偉人")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("プロフィール")
                }
        }
    }
}

// MARK: - Timer View
struct TimerView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.4), .purple.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                if let user = viewModel.user {
                    UserStatusCard(user: user)
                }
                
                TimerDisplay(timeValue: viewModel.timerValue)
                
                TimerButton(
                    isRunning: viewModel.isTimerRunning,
                    onTap: {
                        if viewModel.isTimerRunning {
                            viewModel.stopTimer()
                        } else {
                            viewModel.startTimer()
                        }
                    }
                )
                
                PartnerCard(partner: viewModel.currentPartner)
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - User Status Card
struct UserStatusCard: View {
    let user: User
    
    var body: some View {
        HStack {
            Text("Lv. \(user.level)")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                ProgressView(value: user.experience, total: user.experienceForNextLevel)
                    .tint(.yellow)
                    .frame(width: 150)
                
                Text("EXP: \(Int(user.experience)) / \(Int(user.experienceForNextLevel))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Timer Display
struct TimerDisplay: View {
    let timeValue: TimeInterval
    
    var body: some View {
        Text(formatTime(timeValue))
            .font(.system(size: 64, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Timer Button
struct TimerButton: View {
    let isRunning: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(isRunning ? "STOP" : "START")
                .font(.title)
                .fontWeight(.bold)
                .frame(width: 180, height: 180)
                .background(isRunning ? Color.red : Color.green)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .scaleEffect(isRunning ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isRunning)
    }
}

// MARK: - Partner Card
struct PartnerCard: View {
    let partner: GreatPerson?
    
    var body: some View {
        HStack {
            Image(systemName: partner?.imageName ?? "questionmark.circle")
                .font(.title)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                if let partner = partner {
                    Text("パートナー: \(partner.name)")
                        .font(.headline)
                    Text("スキル: \(partner.skill.name) (\(String(format: "%.0f", (partner.skill.value - 1) * 100))% EXP UP)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("パートナーがいません")
                        .font(.headline)
                    Text("偉人タブからパートナーを選択してください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Ranking View
struct RankingView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.ranking.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("ランキングデータがありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("下にスワイプして更新してください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.ranking) { user in
                        RankingRow(user: user)
                    }
                }
            }
            .navigationTitle("全国ランキング")
            .onAppear {
                viewModel.loadRanking()
            }
            .refreshable {
                viewModel.loadRanking()
            }
        }
    }
}

// MARK: - Ranking Row
struct RankingRow: View {
    let user: User
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        HStack {
            Text("\(user.rank ?? 0)")
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: 40)
                .foregroundColor(rankColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.nickname)
                    .fontWeight(.semibold)
                Text("Lv. \(user.level)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(viewModel.formatTime(user.totalStudyTime))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var rankColor: Color {
        switch user.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .primary
        }
    }
}

// MARK: - Hero Selection View
struct HeroSelectionView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    private var unlockedPersons: [GreatPerson] {
        guard let user = viewModel.user else { return [] }
        return viewModel.availablePersons.filter { person in
            guard let personId = person.id else { return false }
            return user.unlockedPersonIDs.contains(personId)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if unlockedPersons.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("解放された偉人がいません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("レベルを上げて偉人を解放しましょう")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(unlockedPersons) { person in
                        HeroRow(person: person)
                    }
                }
            }
            .navigationTitle("偉人を選択")
        }
    }
}

// MARK: - Hero Row
struct HeroRow: View {
    let person: GreatPerson
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        HStack {
            Image(systemName: person.imageName)
                .font(.system(size: 30))
                .frame(width: 50)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(person.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("スキル: \(person.skill.name)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            if viewModel.currentPartner?.id == person.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.setPartner(person)
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var nickname: String = ""
    @State private var showSaveAlert: Bool = false
    @State private var isEditing: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("プロフィール設定")) {
                    HStack {
                        Text("ニックネーム")
                        Spacer()
                        if isEditing {
                            TextField("ニックネーム", text: $nickname)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        } else {
                            Text(nickname.isEmpty ? "未設定" : nickname)
                                .foregroundColor(nickname.isEmpty ? .secondary : .primary)
                        }
                    }
                }
                
                if let user = viewModel.user {
                    Section(header: Text("統計情報")) {
                        HStack {
                            Text("レベル")
                            Spacer()
                            Text("Lv. \(user.level)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("総学習時間")
                            Spacer()
                            Text(viewModel.formatTime(user.totalStudyTime))
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("解放済み偉人数")
                            Spacer()
                            Text("\(user.unlockedPersonIDs.count)人")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section {
                    if isEditing {
                        HStack {
                            Button("キャンセル") {
                                nickname = viewModel.user?.nickname ?? ""
                                isEditing = false
                            }
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("保存") {
                                saveProfile()
                            }
                            .fontWeight(.semibold)
                            .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button("プロフィールを編集") {
                            isEditing = true
                        }
                    }
                }
            }
            .navigationTitle("プロフィール")
            .onAppear {
                nickname = viewModel.user?.nickname ?? ""
            }
            .alert("保存しました", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private func saveProfile() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { return }
        
        viewModel.user?.nickname = trimmedNickname
        
        Task {
            do {
                try await viewModel.saveUserData()
                await MainActor.run {
                    isEditing = false
                    showSaveAlert = true
                }
            } catch {
                print("プロフィール保存エラー: \(error)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
