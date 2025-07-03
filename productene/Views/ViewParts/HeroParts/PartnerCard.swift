//
//  PartnerCard.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

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
