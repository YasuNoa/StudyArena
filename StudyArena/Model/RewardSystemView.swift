//
//  RewardSystemView.swift
//  StudyArena
//
//  Created by 田中正造 on 11/08/2025.
//


import SwiftUI

struct RewardSystemView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // 背景
            MinimalDarkBackgroundView()
            
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("報酬システム")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // バランス用の透明ボタン
                    Button(action: {}) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .opacity(0)
                    }
                    .disabled(true)
                }
                .padding()
                
                // タブ選択
                Picker("", selection: $selectedTab) {
                    Text("概要").tag(0)
                    Text("トロフィー").tag(1)
                    Text("文字数").tag(2)
                    Text("いいね").tag(3)
                    Text("計算式").tag(4)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .colorScheme(.dark)
                
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case 0:
                            OverviewSection()
                        case 1:
                            TrophySection()
                        case 2:
                            CharacterLimitSection()
                        case 3:
                            LikeLimitSection()
                        case 4:
                            FormulaSection()
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

// MARK: - 概要セクション
struct OverviewSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("レベルアップシステム", systemImage: "arrow.up.circle.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text("学習時間に応じて経験値を獲得し、レベルが上がります。レベルが上がると様々な報酬が解放されます。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("非線形成長システム", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("報酬は非線形で増加します。初期は成長を実感しやすく、後半は達成感のある設計になっています。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("無限の成長", systemImage: "infinity")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    Text("レベル100以降も成長は続きます。プラチナ、ダイヤモンド、マスターといった上位トロフィーが待っています。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // 主要マイルストーン
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("主要マイルストーン", systemImage: "flag.checkered")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        MilestoneRow(level: 10, description: "初心者卒業")
                        MilestoneRow(level: 30, description: "中級者認定")
                        MilestoneRow(level: 50, description: "上級者の仲間入り")
                        MilestoneRow(level: 100, description: "レジェンド達成")
                        MilestoneRow(level: 200, description: "グランドマスター")
                    }
                }
            }
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("レベル到達目安時間", systemImage: "clock.fill")
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TimeEstimateRow(level: 10, time: "約34分")
                        TimeEstimateRow(level: 30, time: "約5時間28分")
                        TimeEstimateRow(level: 50, time: "約17時間25分")
                        TimeEstimateRow(level: 75, time: "約43時間44分")
                        TimeEstimateRow(level: 100, time: "約85時間25分")
                        TimeEstimateRow(level: 150, time: "約215時間")
                        TimeEstimateRow(level: 200, time: "約417時間")
                    }
                    
                    Text("※1秒 = 1EXPで計算")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - トロフィーセクション
struct TrophySection: View {
    let trophies: [(range: String, tier: String, color: Color, icon: String)] = [
        ("Lv.1-20", "ブロンズ", Color(red: 0.8, green: 0.5, blue: 0.2), "shield.fill"),
        ("Lv.21-50", "シルバー", Color(white: 0.7), "shield.lefthalf.filled"),
        ("Lv.51-100", "ゴールド", Color.yellow, "crown.fill"),
        ("Lv.101-150", "プラチナ", Color.cyan, "star.circle.fill"),
        ("Lv.151-200", "ダイヤモンド", Color.purple, "rhombus.fill"),
        ("Lv.201+", "マスター", Color.red, "flame.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(trophies, id: \.tier) { trophy in
                InfoCard {
                    HStack(spacing: 16) {
                        Image(systemName: trophy.icon)
                            .font(.system(size: 40))
                            .foregroundColor(trophy.color)
                            .shadow(color: trophy.color.opacity(0.5), radius: 5)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trophy.tier)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(trophy.range)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            // 各ランクの詳細
                            HStack(spacing: 8) {
                                ForEach(["I", "II", "III"], id: \.self) { rank in
                                    Text(rank)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(trophy.color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(trophy.color.opacity(0.2))
                                        )
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - 文字数セクション
struct CharacterLimitSection: View {
    let milestones: [(level: Int, chars: Int)] = [
        (1, 5),
        (5, 7),
        (10, 12),
        (20, 17),
        (30, 21),
        (50, 28),
        (75, 36),
        (100, 43),
        (150, 56),
        (200, 68)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("投稿文字数の成長", systemImage: "text.badge.plus")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("計算式: 5 + floor(レベル^0.58 × 5.5)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("レベルが上がるごとに投稿できる文字数が増えます。非線形で増加するため、初期は頻繁に、後半は緩やかに増えます。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // グラフ風の表示
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("文字数マイルストーン")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(milestones, id: \.level) { milestone in
                        HStack {
                            Text("Lv.\(milestone.level)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 50, alignment: .leading)
                            
                            // プログレスバー風の表示
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.6), .cyan.opacity(0.6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * CGFloat(milestone.chars) / 70)
                                }
                            }
                            .frame(height: 16)
                            
                            Text("\(milestone.chars)文字")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - いいねセクション
struct LikeLimitSection: View {
    let milestones: [(level: Int, likes: Int)] = [
        (1, 2),
        (5, 5),
        (10, 9),
        (20, 15),
        (30, 21),
        (50, 31),
        (75, 41),
        (100, 50),
        (150, 66),
        (200, 81)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("いいね機能", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundColor(.pink)
                    
                    Text("計算式: floor(レベル^0.65 × 2)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.pink.opacity(0.7))
                    
                    Text("1日に使える「いいね」の回数がレベルと共に増加します。毎日0時にリセットされます。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // いいね数の表示
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("いいね回数マイルストーン")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(milestones, id: \.level) { milestone in
                        HStack {
                            Text("Lv.\(milestone.level)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 50, alignment: .leading)
                            
                            // ハートアイコンで表示
                            HStack(spacing: 2) {
                                ForEach(0..<min(milestone.likes, 10), id: \.self) { _ in
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.pink.opacity(0.7))
                                }
                                if milestone.likes > 10 {
                                    Text("+\(milestone.likes - 10)")
                                        .font(.caption2)
                                        .foregroundColor(.pink.opacity(0.7))
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(milestone.likes)回/日")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.pink)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 計算式セクション
struct FormulaSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 16) {
                    Label("報酬計算式", systemImage: "function")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    // 経験値
                    VStack(alignment: .leading, spacing: 8) {
                        Text("必要経験値")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                        
                        Text("EXP = level × 100 + level^1.5 × 50")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("レベルが上がるほど必要経験値が増加")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    
                    // 文字数
                    VStack(alignment: .leading, spacing: 8) {
                        Text("投稿文字数")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text("文字数 = 5 + floor(level^0.58 × 5.5)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("非線形増加（最大200文字）")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // いいね
                    VStack(alignment: .leading, spacing: 8) {
                        Text("いいね回数")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.pink)
                        
                        Text("いいね = floor(level^0.65 × 2)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("1日あたりの使用可能回数（最大500回）")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("設計思想", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("• 初期レベルでは成長を実感しやすい\n• 中盤以降は達成感のある緩やかな成長\n• レベル100以降も無限に成長可能\n• 各要素が異なる成長曲線を持つ")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                }
            }
        }
    }
}

// MARK: - コンポーネント
struct InfoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

struct MilestoneRow: View {
    let level: Int
    let description: String
    
    var body: some View {
        HStack {
            Text("Lv.\(level)")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.orange)
                .frame(width: 50, alignment: .leading)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

struct TimeEstimateRow: View {
    let level: Int
    let time: String
    
    var body: some View {
        HStack {
            Text("Lv.\(level)")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.cyan)
                .frame(width: 50, alignment: .leading)
            
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            
            Text(time)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

#if DEBUG
#Preview {
    RewardSystemView()
}
#endif
