//
//  MBTIStatsView.swift
//  StudyArena
//
//  Created by 田中正造 on 22/08/2025.
//


import SwiftUI

struct MBTIStatsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedMBTI: String? = nil
    @State private var showMBTISelector = false
    
    // MBTI別の平均勉強時間（ダミーデータ）
    let mbtiStats: [String: (avgTime: String, rank: Int, description: String)] = [
        "INTJ": ("4.2時間", 1, "戦略的に計画を立てて黙々と"),
        "INFJ": ("3.8時間", 3, "理想に向かって静かに燃える"),
        "ISTJ": ("4.0時間", 2, "ルーティンを守り着実に"),
        "ISFJ": ("3.5時間", 5, "みんなのために頑張る"),
        "INTP": ("3.7時間", 4, "興味のある分野に没頭"),
        "INFP": ("3.2時間", 8, "気分が乗ったら爆発的に"),
        "ISTP": ("2.8時間", 12, "実践的なことなら集中"),
        "ISFP": ("2.5時間", 15, "好きな環境で自分のペースで"),
        "ENTJ": ("3.4時間", 6, "目標達成のため効率的に"),
        "ENFJ": ("3.3時間", 7, "仲間と切磋琢磨しながら"),
        "ESTJ": ("3.1時間", 9, "スケジュール通りきっちり"),
        "ESFJ": ("2.9時間", 11, "グループ学習で力を発揮"),
        "ENTP": ("3.0時間", 10, "新しい方法を試しながら"),
        "ENFP": ("2.7時間", 13, "楽しみながらマイペース"),
        "ESTP": ("2.4時間", 16, "短期集中型で効率重視"),
        "ESFP": ("2.6時間", 14, "友達と一緒なら頑張れる")
    ]
    
    var body: some View {
        ZStack {
            MinimalDarkBackgroundView()
            
            ScrollView {
                VStack(spacing: 20) {
                    // タイトル
                    Text("MBTI別 平均勉強時間")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    // 自分のMBTI設定
                    if let myMBTI = viewModel.user?.mbtiType {
                        MyMBTICard(mbti: myMBTI, stats: mbtiStats[myMBTI])
                    } else {
                        Button(action: { showMBTISelector = true }) {
                            Text("あなたのMBTIを設定")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(10)
                        }
                    }
                    
                    // ランキング表示
                    VStack(alignment: .leading, spacing: 10) {
                        Text("勉強時間ランキング")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)
                        
                        ForEach(mbtiStats.sorted(by: { $0.value.rank < $1.value.rank }), id: \.key) { mbti, stats in
                            MBTIRankingRow(
                                rank: stats.rank,
                                mbti: mbti,
                                avgTime: stats.avgTime,
                                description: stats.description,
                                isMyType: mbti == viewModel.user?.mbtiType
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    // 免責事項
                    Text("※ この統計は完全にネタです。MBTIと勉強時間に科学的な相関はありません。")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showMBTISelector) {
            MBTISelectionView(selectedMBTI: $selectedMBTI)
        }
    }
}

struct MBTIRankingRow: View {
    let rank: Int
    let mbti: String
    let avgTime: String
    let description: String
    let isMyType: Bool
    
    var body: some View {
        HStack {
            // ランク
            Text("#\(rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 30)
            
            // MBTI
            Text(mbti)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isMyType ? .yellow : .white)
                .frame(width: 50)
            
            // 説明
            VStack(alignment: .leading, spacing: 2) {
                Text(avgTime)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isMyType ? Color.yellow.opacity(0.1) : Color.white.opacity(0.05))
        )
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.7)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .white.opacity(0.7)
        }
    }
}