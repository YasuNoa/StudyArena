//
//  MyDepartmentListView.swift
//  StudyArena
//
//  Created by 田中正造 on 2025/01/17.
//
//  自分が所属している部門の一覧を表示するビュー
//

import SwiftUI

struct MyDepartmentListView: View {
    @ObservedObject var departmentViewModel: DepartmentViewModel
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            MinimalDarkBackgroundView()
            
            if departmentViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            } else if departmentViewModel.userDepartments.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(departmentViewModel.userDepartments) { membership in
                            // membershipからDepartmentオブジェクトを探す
                            // 見つからない場合は最低限の情報で仮構築（詳細画面で再ロードされる等の運用次第だが、
                            // 通常はloadDepartmentsで取得済みのはず）
                            if let department = getDepartment(for: membership) {
                                NavigationLink(destination: DepartmentDetailView(department: department)
                                    .environmentObject(viewModel)
                                ) {
                                    // 共通化したDepartmentCardを使用
                                    DepartmentCard(
                                        department: department,
                                        role: membership.role
                                    ) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("所属部門")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar) // タイトルを白にする（背景が暗いため）
        
        .task {
            // データ読み込み
            if let user = viewModel.user {
                departmentViewModel.userId = user.id
                departmentViewModel.user = user
                await departmentViewModel.loadDepartments()
                await departmentViewModel.loadUserMemberships()
            }
        }
    }
    
    // MARK: - Components
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("所属している部門はありません")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            
            Text("「部門を探す」から新しい部門に参加してみましょう")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private func getDepartment(for membership: DepartmentMembership) -> Department? {
        return departmentViewModel.departments.first { $0.id == membership.departmentId }
    }
}
