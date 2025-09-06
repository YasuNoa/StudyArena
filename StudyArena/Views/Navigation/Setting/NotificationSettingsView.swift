//
//  NotificationSettingsView.swift
//  StudyArena
//
//  Created by 田中正造 on 2025/09/06.
//


import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                MinimalDarkBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 権限状態
                        PermissionStatusCard(
                            isAuthorized: notificationManager.isAuthorized,
                            showingAlert: $showingPermissionAlert
                        )
                        
                        // 通知設定一覧
                        VStack(spacing: 15) {
                            ForEach($notificationManager.notificationSettings) { $setting in
                                NotificationSettingRow(setting: $setting)
                            }
                        }
                        .padding(.horizontal)
                        
                        // テスト通知ボタン
                        if notificationManager.isAuthorized {
                            TestNotificationButton()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("通知設定")
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
        .alert("通知権限が必要です", isPresented: $showingPermissionAlert) {
            Button("設定を開く") {
                openAppSettings()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("通知を受け取るには、iOSの設定で通知を許可してください。")
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - 権限状態カード
struct PermissionStatusCard: View {
    let isAuthorized: Bool
    @Binding var showingAlert: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(isAuthorized ? Color("green") : Color("orange"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isAuthorized ? "通知が有効です" : "通知が無効です")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(isAuthorized ? "学習リマインダーを受け取れます" : "設定で通知を許可してください")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            if !isAuthorized {
                Button("有効にする") {
                    showingAlert = true
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color("orange"))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isAuthorized ? Color("green").opacity(0.3) : Color("orange").opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - 通知設定行
struct NotificationSettingRow: View {
    @Binding var setting: NotificationSetting
    @State private var showingTimePicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(setting.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(setting.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Toggle("", isOn: $setting.isEnabled)
                    .tint(Color("blue"))
                    .onChange(of: setting.isEnabled) { _, newValue in
                        NotificationManager.shared.updateNotificationSetting(setting)
                    }
            }
            
            // 時間設定（時間ベースの通知の場合）
            if setting.isEnabled && setting.time != nil {
                HStack {
                    Text("時間:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Button(action: { showingTimePicker = true }) {
                        Text(formatTime(setting.time))
                            .font(.subheadline)
                            .foregroundColor(Color("blue"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("blue").opacity(0.1))
                            )
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(setting: $setting)
        }
    }
    
    private func formatTime(_ dateComponents: DateComponents?) -> String {
        guard let components = dateComponents,
              let hour = components.hour,
              let minute = components.minute else {
            return "未設定"
        }
        
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - 時間選択シート
struct TimePickerSheet: View {
    @Binding var setting: NotificationSetting
    @Environment(\.dismiss) var dismiss
    @State private var selectedTime = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("通知時間を選択")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top)
                
                DatePicker(
                    "時間",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .colorScheme(.dark)
                .padding()
                
                Spacer()
            }
            .background(MinimalDarkBackgroundView())
            .navigationTitle("時間設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        setting.time = components
                        NotificationManager.shared.updateNotificationSetting(setting)
                        dismiss()
                    }
                    .foregroundColor(Color("blue"))
                }
            }
        }
        .onAppear {
            if let components = setting.time,
               let hour = components.hour,
               let minute = components.minute {
                let calendar = Calendar.current
                selectedTime = calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
            }
        }
    }
}

// MARK: - テスト通知ボタン
struct TestNotificationButton: View {
    var body: some View {
        Button(action: sendTestNotification) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.headline)
                Text("テスト通知を送信")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color("blue"), Color("cyan")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private func sendTestNotification() {
        NotificationManager.shared.sendStudyCompletedNotification(
            duration: 1800, // 30分
            earnedExp: 100
        )
    }
}

#if DEBUG
#Preview {
    NotificationSettingsView()
}
#endif