//
//  RewardSystemView.swift - レベル10000対応版
//  StudyArena
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
                            TrophySectionUpdated()
                        case 2:
                            CharacterLimitSectionUpdated()
                        case 3:
                            LikeLimitSectionUpdated()
                        case 4:
                            FormulaSectionUpdated()
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

// MARK: - 概要セクション（更新版）
struct OverviewSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("無限のレベルアップシステム", systemImage: "arrow.up.circle.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text("レベル10000以上まで対応！学習時間に応じて経験値を獲得し、非線形でレベルが上がります。高レベルになるほど必要経験値が増加します。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("対数的成長システム", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("報酬は対数関数や累乗関数で計算。初期は成長を実感しやすく、後半は壮大な目標として機能します。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("10段階のトロフィー", systemImage: "trophy.fill")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    Text("ブロンズからエターナルまで10種類のトロフィー。各3段階で合計30のランクが存在します。")
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
                        MilestoneRow(level: 10, description: "ブロンズ卒業")
                        MilestoneRow(level: 30, description: "シルバー卒業")
                        MilestoneRow(level: 75, description: "ゴールド卒業")
                        MilestoneRow(level: 175, description: "プラチナ卒業")
                        MilestoneRow(level: 400, description: "ダイヤモンド卒業")
                        MilestoneRow(level: 900, description: "マスター卒業")
                        MilestoneRow(level: 2000, description: "グランドマスター卒業")
                        MilestoneRow(level: 4500, description: "レジェンド卒業")
                        MilestoneRow(level: 10000, description: "ミシック卒業→エターナル")
                    }
                }
            }
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("レベル到達目安時間", systemImage: "clock.fill")
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TimeEstimateRow(level: 10, time: User.estimatedTimeForLevel(10))
                        TimeEstimateRow(level: 50, time: User.estimatedTimeForLevel(50))
                        TimeEstimateRow(level: 100, time: User.estimatedTimeForLevel(100))
                        TimeEstimateRow(level: 500, time: User.estimatedTimeForLevel(500))
                        TimeEstimateRow(level: 1000, time: User.estimatedTimeForLevel(1000))
                        TimeEstimateRow(level: 5000, time: User.estimatedTimeForLevel(5000))
                        TimeEstimateRow(level: 10000, time: User.estimatedTimeForLevel(10000))
                    }
                    
                    Text("※1秒 = 1EXPで計算")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - トロフィーセクション（更新版）
struct TrophySectionUpdated: View {
    let trophies: [(range: String, tier: String, color: Color, icon: String)] = [
        ("Lv.1-10", "ブロンズ", Color(red: 0.8, green: 0.5, blue: 0.2), "shield.fill"),
        ("Lv.11-30", "シルバー", Color(white: 0.7), "shield.lefthalf.filled"),
        ("Lv.31-75", "ゴールド", Color.yellow, "crown.fill"),
        ("Lv.76-175", "プラチナ", Color.cyan, "star.circle.fill"),
        ("Lv.176-400", "ダイヤモンド", Color.purple, "rhombus.fill"),
        ("Lv.401-900", "マスター", Color.red, "flame.fill"),
        ("Lv.901-2000", "グランドマスター", Color(red: 1.0, green: 0.5, blue: 0.0), "bolt.circle.fill"),
        ("Lv.2001-4500", "レジェンド", Color(red: 0.0, green: 1.0, blue: 0.5), "sparkles"),
        ("Lv.4501-10000", "ミシック", Color(red: 0.8, green: 0.0, blue: 1.0), "moon.stars.fill"),
        ("Lv.10001+", "エターナル", Color(red: 1.0, green: 0.84, blue: 0.0), "infinity.circle.fill")
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

// MARK: - 文字数セクション（更新版）
struct CharacterLimitSectionUpdated: View {
    let milestones: [(level: Int, chars: Int)] = User.getCharacterMilestones()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("投稿文字数の成長", systemImage: "text.badge.plus")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("計算式: 5 + log10(level+1) × 25 × level^0.15")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("対数関数による非線形増加。レベル10000で約300文字、最大500文字。")
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
                                .frame(width: 60, alignment: .leading)
                            
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
                                        .frame(width: geometry.size.width * CGFloat(milestone.chars) / 500)
                                }
                            }
                            .frame(height: 16)
                            
                            Text("\(milestone.chars)文字")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - いいねセクション（更新版）
struct LikeLimitSectionUpdated: View {
    let milestones: [(level: Int, likes: Int)] = User.getLikeMilestones()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("いいね機能", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundColor(.pink)
                    
                    Text("計算式: 3 + √level × 5 + log10(level+1) × 10")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.pink.opacity(0.7))
                    
                    Text("平方根ベースの非線形増加。レベル10000で約800回/日、最大1000回。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
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
                                .frame(width: 60, alignment: .leading)
                            
                            // ハートアイコンで表示
                            HStack(spacing: 2) {
                                ForEach(0..<min(milestone.likes/50, 10), id: \.self) { _ in
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.pink.opacity(0.7))
                                }
                                Text("\(milestone.likes)")
                                    .font(.caption2)
                                    .foregroundColor(.pink.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Text("\(milestone.likes)回/日")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.pink)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 計算式セクション（更新版）
struct FormulaSectionUpdated: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 16) {
                    Label("報酬計算式（レベル10000対応）", systemImage: "function")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    // 経験値
                    VStack(alignment: .leading, spacing: 8) {
                        Text("必要経験値")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                        
                        Text("EXP = level × 50 + level^1.8 × 10")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("累乗関数による非線形増加")
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
                        
                        Text("文字 = 5 + log10(lv+1) × 25 × lv^0.15")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("対数関数による緩やかな増加（最大500文字）")
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
                        
                        Text("回数 = 3 + √lv × 5 + log10(lv+1) × 10")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("平方根による緩やかな増加（最大1000回）")
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
                    
                    Text("• 対数・累乗関数で無限スケール対応\n• 初期は急成長、後半は緩やかな成長\n• レベル10000以降も継続可能\n• 各要素が異なる成長曲線\n• 最大値で適切にキャップ")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                }
            }
        }
    }
}

// MARK: - コンポーネント（共通）
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
                .frame(width: 60, alignment: .leading)
            
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
                .frame(width: 60, alignment: .leading)
            
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
