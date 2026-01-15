//
//  RewardSystemView.swift - ダイヤモンドまで版
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
                    Text("計算式").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .colorScheme(.dark)
                
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case 0:
                            OverviewSectionDiamond()
                        case 1:
                            TrophySectionDiamond()
                        case 2:
                            CharacterLimitSectionDiamond()
                        case 3:
                            FormulaSectionDiamond()
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

// MARK: - 概要セクション（ダイヤモンド版）
struct OverviewSectionDiamond: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("現実的なレベルアップシステム", systemImage: "arrow.up.circle.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text("レベル200程度まで楽しめる現実的な設計。学習時間に応じて経験値を獲得し、適度な成長曲線でレベルアップします。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("5段階のトロフィー", systemImage: "trophy.fill")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    Text("ブロンズからダイヤモンドまで5種類のトロフィー。各3段階で合計15のランクが存在します。")
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
                        MilestoneRow(level: 20, description: "ブロンズ卒業 → 10文字投稿")
                        MilestoneRow(level: 50, description: "シルバー卒業 → 15文字投稿")
                        MilestoneRow(level: 100, description: "ゴールド卒業 → 20文字投稿")
                        MilestoneRow(level: 175, description: "プラチナ卒業 → 25文字投稿")
                        MilestoneRow(level: 176, description: "ダイヤモンド到達！💎")
                        MilestoneRow(level: 200, description: "ダイヤモンドII")
                        MilestoneRow(level: 250, description: "ダイヤモンドIII")
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
                        TimeEstimateRow(level: 25, time: User.estimatedTimeForLevel(25))
                        TimeEstimateRow(level: 50, time: User.estimatedTimeForLevel(50))
                        TimeEstimateRow(level: 100, time: User.estimatedTimeForLevel(100))
                        TimeEstimateRow(level: 150, time: User.estimatedTimeForLevel(150))
                        TimeEstimateRow(level: 200, time: User.estimatedTimeForLevel(200))
                        TimeEstimateRow(level: 250, time: User.estimatedTimeForLevel(250))
                    }
                    
                    Text("※1秒 = 1EXPで計算")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - トロフィーセクション（ダイヤモンド版）
struct TrophySectionDiamond: View {
    let trophies: [(range: String, tier: String, color: Color, icon: String)] = [
        ("Lv.1-20", "ブロンズ", Color(red: 0.8, green: 0.5, blue: 0.2), "shield.fill"),
        ("Lv.21-50", "シルバー", Color(white: 0.7), "shield.lefthalf.filled"),
        ("Lv.51-100", "ゴールド", Color.yellow, "crown.fill"),
        ("Lv.101-175", "プラチナ", Color.cyan, "star.circle.fill"),
        ("Lv.176+", "ダイヤモンド", Color.purple, "rhombus.fill")
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
                        
                        // 特別な説明
                        if trophy.tier == "ダイヤモンド" {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("最高ランク")
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                                Text("Lv.176以上")
                                    .font(.caption2)
                                    .foregroundColor(.purple.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 文字数セクション（ダイヤモンド版）
struct CharacterLimitSectionDiamond: View {
    let milestones: [(level: Int, chars: Int)] = User.getCharacterMilestones()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("投稿文字数の成長", systemImage: "text.badge.plus")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("レベルに応じて段階的に増加。最大150文字まで投稿可能になります。")
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
                                        .frame(width: geometry.size.width * CGFloat(milestone.chars) / 25)  // ← 500を25に変更
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

// MARK: - 計算式セクション（ダイヤモンド版）
struct FormulaSectionDiamond: View {
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
                        
                        Text("EXP = level × 100 + level^1.5 × 20")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("緩やかな累乗増加（現実的な成長）")
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
                        
                        Text("文字数 = レベル段階に応じた固定値")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("段階的増加（最大25文字）")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("設計思想", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("• 現実的で達成可能な目標設定\n• 段階的で分かりやすい成長\n• レベル200程度まで楽しめる設計\n• 過度なインフレを避けた適度な報酬\n• 長期的なモチベーション維持")
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
