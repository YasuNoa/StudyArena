//
//  HeroRow.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

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
