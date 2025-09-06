//
//  DepartmentBrowserView.swift
//  StudyArena
//
//  Created by 田中正造 on 2025/09/06.
//
import SwiftUI

struct DepartmentBrowserView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: Department.DepartmentCategory = .study
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                
                VStack(spacing: 0) {
                    // カテゴリ選択
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Department.DepartmentCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 検索バー
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                        
                        TextField("部門を検索", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // 部門リスト
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(PresetDepartments.defaults.filter { 
                                $0.category == selectedCategory 
                            }) { dept in
                                DepartmentCard(department: dept)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("部門を探す")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}
