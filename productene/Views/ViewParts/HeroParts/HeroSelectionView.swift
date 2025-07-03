//
//  HeroSelectionView.swift
//  productene
//
//  Created by 田中正造 on 03/07/2025.
//
import SwiftUI

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
