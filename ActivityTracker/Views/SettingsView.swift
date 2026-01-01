//
//  SettingsView.swift
//  ActivityTracker
//
//  设置视图
//  管理应用的各项配置
//

import SwiftUI
import ServiceManagement

/// 设置视图
struct SettingsView: View {
    
    // MARK: - Observed Objects
    
    @ObservedObject var dataStore = DataStore.shared
    @ObservedObject var tracker = AppTracker.shared
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State - 基础设置
    
    @State private var samplingInterval: Double
    @State private var idleThreshold: Double
    @State private var enableWindowTitle: Bool
    @State private var dataRetentionDays: Int
    @State private var launchAtLogin: Bool
    
    // MARK: - State - 功能开关
    
    @State private var enableProjectDetection: Bool
    @State private var enableActivityLabels: Bool
    @State private var enableMeetingDetection: Bool
    @State private var enableEngagementScore: Bool
    @State private var enableInputStats: Bool
    @State private var enableGoals: Bool
    @State private var enableFocusSessions: Bool
    @State private var enableDataRedaction: Bool
    
    // MARK: - State - UI
    
    @State private var selectedTab = 0
    
    // MARK: - Initialization
    
    init() {
        let settings = DataStore.shared.settings
        _samplingInterval = State(initialValue: settings.samplingInterval)
        _idleThreshold = State(initialValue: settings.idleThreshold)
        _enableWindowTitle = State(initialValue: settings.enableWindowTitle)
        _dataRetentionDays = State(initialValue: settings.dataRetentionDays)
        _launchAtLogin = State(initialValue: settings.launchAtLogin)
        
        _enableProjectDetection = State(initialValue: settings.enableProjectDetection)
        _enableActivityLabels = State(initialValue: settings.enableActivityLabels)
        _enableMeetingDetection = State(initialValue: settings.enableMeetingDetection)
        _enableEngagementScore = State(initialValue: settings.enableEngagementScore)
        _enableInputStats = State(initialValue: settings.enableInputStats)
        _enableGoals = State(initialValue: settings.enableGoals)
        _enableFocusSessions = State(initialValue: settings.enableFocusSessions)
        _enableDataRedaction = State(initialValue: settings.enableDataRedaction)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.headline)
            
            // 标签页选择器 - 使用按钮组
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    Button(action: { selectedTab = index }) {
                        Text(["基础", "功能", "隐私"][index])
                            .font(.caption)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(selectedTab == index ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            
            // 标签页内容
            Group {
                switch selectedTab {
                case 0:
                    basicSettingsView
                case 1:
                    featureSettingsView
                case 2:
                    privacySettingsView
                default:
                    basicSettingsView
                }
            }
            .frame(maxHeight: .infinity)
            
            // 操作按钮
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 380, height: 480)
    }
    
    // MARK: - Basic Settings View
    
    /// 基础设置
    private var basicSettingsView: some View {
        Form {
            Section("追踪") {
                VStack(alignment: .leading) {
                    Text("采样间隔: \(String(format: "%.1f", samplingInterval))s")
                    Slider(value: $samplingInterval, in: 0.5...5.0, step: 0.5)
                }
                
                VStack(alignment: .leading) {
                    Text("空闲阈值: \(Int(idleThreshold))s")
                    Slider(value: $idleThreshold, in: 60...600, step: 30)
                }
            }
            
            Section("数据") {
                Picker("保留天数", selection: $dataRetentionDays) {
                    Text("7 天").tag(7)
                    Text("30 天").tag(30)
                    Text("90 天").tag(90)
                    Text("180 天").tag(180)
                }
            }
            
            Section("系统") {
                Toggle("开机启动", isOn: $launchAtLogin)
            }
            
            Section("危险操作") {
                Button("清空今日数据", role: .destructive) {
                    dataStore.clearTodayData()
                    StatisticsManager.shared.refresh()
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Feature Settings View
    
    /// 功能设置
    private var featureSettingsView: some View {
        Form {
            Section("自动分类") {
                Toggle("项目识别", isOn: $enableProjectDetection)
                Toggle("活动标签", isOn: $enableActivityLabels)
                Toggle("会议检测", isOn: $enableMeetingDetection)
            }
            
            Section("生产力") {
                Toggle("专注会话", isOn: $enableFocusSessions)
                Toggle("目标提醒", isOn: $enableGoals)
            }
            
            Section("高级 (需要 Accessibility 权限)") {
                Toggle("窗口标题", isOn: $enableWindowTitle)
                Toggle("输入统计", isOn: $enableInputStats)
                    .onChange(of: enableInputStats) { newValue in
                        if newValue {
                            _ = EngagementTracker.checkAccessibilityPermission()
                        }
                    }
                Toggle("参与度评分", isOn: $enableEngagementScore)
                    .disabled(!enableInputStats)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Privacy Settings View
    
    /// 隐私设置
    private var privacySettingsView: some View {
        Form {
            Section("数据脱敏") {
                Toggle("启用脱敏", isOn: $enableDataRedaction)
                Text("自动隐藏邮箱、Token 等敏感信息")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("应用过滤") {
                NavigationLink("黑名单设置") {
                    BlacklistView()
                }
            }
            
            Section("数据位置") {
                Text("~/Library/Application Support/ActivityTracker/")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("在 Finder 中显示") {
                    let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                        .appendingPathComponent("ActivityTracker")
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Save Settings
    
    /// 保存设置
    private func saveSettings() {
        // 基础设置
        dataStore.settings.samplingInterval = samplingInterval
        dataStore.settings.idleThreshold = idleThreshold
        dataStore.settings.enableWindowTitle = enableWindowTitle
        dataStore.settings.dataRetentionDays = dataRetentionDays
        dataStore.settings.launchAtLogin = launchAtLogin
        
        // 功能开关
        dataStore.settings.enableProjectDetection = enableProjectDetection
        dataStore.settings.enableActivityLabels = enableActivityLabels
        dataStore.settings.enableMeetingDetection = enableMeetingDetection
        dataStore.settings.enableEngagementScore = enableEngagementScore
        dataStore.settings.enableInputStats = enableInputStats
        dataStore.settings.enableGoals = enableGoals
        dataStore.settings.enableFocusSessions = enableFocusSessions
        dataStore.settings.enableDataRedaction = enableDataRedaction
        
        dataStore.saveSettings()
        
        // 重启追踪以应用新设置
        if tracker.isTracking {
            tracker.stopTracking()
            tracker.startTracking()
        }
        
        // 更新开机启动
        updateLaunchAtLogin(launchAtLogin)
    }
    
    /// 更新开机启动设置
    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}

// MARK: - Blacklist View

/// 黑名单设置视图
struct BlacklistView: View {
    
    @ObservedObject var dataStore = DataStore.shared
    @State private var newBundleId = ""
    
    var body: some View {
        VStack {
            // 黑名单列表
            List {
                ForEach(dataStore.settings.blacklistedBundleIds, id: \.self) { bundleId in
                    Text(bundleId)
                }
                .onDelete { indexSet in
                    dataStore.settings.blacklistedBundleIds.remove(atOffsets: indexSet)
                    dataStore.saveSettings()
                }
            }
            
            // 添加新项
            HStack {
                TextField("Bundle ID", text: $newBundleId)
                    .textFieldStyle(.roundedBorder)
                
                Button("添加") {
                    if !newBundleId.isEmpty {
                        dataStore.settings.blacklistedBundleIds.append(newBundleId)
                        dataStore.saveSettings()
                        newBundleId = ""
                    }
                }
            }
            .padding()
        }
        .navigationTitle("黑名单")
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
