//
//  DashboardView.swift
//  ActivityTracker
//
//  主仪表盘视图
//  显示统计卡片、应用排行榜、时间轴和分析数据
//

import SwiftUI

/// 主仪表盘视图
struct DashboardView: View {
    
    // MARK: - Observed Objects
    
    @ObservedObject var tracker = AppTracker.shared
    @ObservedObject var stats = StatisticsManager.shared
    @ObservedObject var dataStore = DataStore.shared
    @ObservedObject var focusManager = FocusSessionManager.shared
    @ObservedObject var switchAnalyzer = SwitchAnalyzer.shared
    
    // MARK: - State
    
    @State private var showSettings = false
    @State private var showBookmarkSheet = false
    @State private var showExportOptions = false
    @State private var selectedTab = 0
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            // 顶部标题栏
            headerView
            
            // 统计卡片
            statsCardsView
            
            // 标签页选择器 - 使用按钮组替代 Picker
            HStack(spacing: 0) {
                TabButton(title: "排行", isSelected: selectedTab == 0, tooltip: "应用使用排行") {
                    selectedTab = 0
                }
                TabButton(title: "时间轴", isSelected: selectedTab == 1, tooltip: "时间轴记录") {
                    selectedTab = 1
                }
                TabButton(title: "分析", isSelected: selectedTab == 2, tooltip: "切换分析") {
                    selectedTab = 2
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            
            // 标签页内容
            Group {
                switch selectedTab {
                case 0:
                    appRankingsView
                case 1:
                    timelineView
                case 2:
                    analysisView
                default:
                    appRankingsView
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(16)
        .frame(width: 380, height: 560)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showBookmarkSheet) {
            BookmarkSheet()
        }
        .onAppear {
            stats.refresh()
            switchAnalyzer.analyze()
        }
    }
    
    // MARK: - Header View
    
    /// 顶部标题栏
    private var headerView: some View {
        HStack {
            Text("Activity Tracker")
                .font(.headline)
            
            Spacer()
            
            // 添加书签按钮
            Button(action: { showBookmarkSheet = true }) {
                Image(systemName: "bookmark.fill")
            }
            .buttonStyle(.plain)
            .tooltip("添加标记")
            
            // 设置按钮
            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
            .tooltip("设置")
            
            // 导出按钮
            Button(action: { showExportOptions = true }) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .tooltip("导出数据")
            .popover(isPresented: $showExportOptions, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    ExportButton(title: "导出 CSV", subtitle: "完整分段数据") {
                        ExportManager.shared.exportCSV()
                        showExportOptions = false
                    }
                    ExportButton(title: "导出 JSON", subtitle: "原始数据") {
                        ExportManager.shared.exportJSON()
                        showExportOptions = false
                    }
                    ExportButton(title: "导出时间账单", subtitle: "按标签汇总工时") {
                        ExportManager.shared.exportTimesheet()
                        showExportOptions = false
                    }
                }
                .padding(8)
            }
        }
    }
    
    // MARK: - Stats Cards View
    
    /// 统计卡片区域
    private var statsCardsView: some View {
        HStack(spacing: 10) {
            // 活跃时间卡片
            StatCard(
                title: "Active",
                value: formatDuration(stats.totalActiveTime),
                icon: "clock.fill",
                color: .blue
            )
            .tooltip("今日活跃时间")
            
            // 专注时间卡片（可点击开始/结束专注）
            StatCard(
                title: "Focus",
                value: formatDuration(focusManager.todayFocusTime()),
                icon: "target",
                color: focusManager.isInFocus ? .green : .gray
            )
            .onTapGesture {
                if focusManager.isInFocus {
                    focusManager.endSession()
                } else {
                    focusManager.startManualSession()
                }
            }
            .tooltip(focusManager.isInFocus ? "点击结束专注" : "点击开始专注")
            
            // 追踪状态卡片（可点击暂停/恢复）
            StatCard(
                title: "Status",
                value: tracker.isTracking ? "Running" : "Paused",
                icon: tracker.isTracking ? "play.fill" : "pause.fill",
                color: tracker.isTracking ? .green : .orange
            )
            .onTapGesture {
                tracker.toggleTracking()
            }
            .tooltip(tracker.isTracking ? "点击暂停" : "点击恢复")
        }
    }
    
    // MARK: - App Rankings View
    
    /// 应用排行榜视图
    private var appRankingsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if stats.topApps.isEmpty {
                Text("No data yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(stats.topApps) { app in
                            AppRankRow(app: app, maxDuration: stats.topApps.first?.totalDuration ?? 1)
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Timeline View
    
    /// 时间轴视图
    private var timelineView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 书签标签
            if !dataStore.todaySummary.bookmarks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dataStore.todaySummary.bookmarks) { bookmark in
                            BookmarkTag(bookmark: bookmark)
                        }
                    }
                }
                .frame(height: 24)
            }
            
            // 分段列表
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(dataStore.todaySummary.segments.suffix(20).reversed()) { segment in
                        TimelineRow(segment: segment)
                    }
                }
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Analysis View
    
    /// 分析视图
    private var analysisView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 碎片化指数卡片
            HStack {
                VStack(alignment: .leading) {
                    Text("碎片化指数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f", switchAnalyzer.fragmentationIndex))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("切换次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(switchAnalyzer.contextSwitchCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
            
            // Top Interrupters
            if !switchAnalyzer.topInterrupters.isEmpty {
                Text("最常打断你的应用")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(switchAnalyzer.topInterrupters.prefix(3), id: \.bundleId) { item in
                    HStack {
                        Text(item.appName)
                            .font(.caption)
                        Spacer()
                        Text("\(item.count) 次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.top, 4)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}

// MARK: - Tab Button

/// 标签页按钮
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let tooltip: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .tooltip(tooltip)
    }
}

// MARK: - Export Button

/// 导出选项按钮
struct ExportButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.001)) // 确保整个区域可点击
        .cornerRadius(4)
    }
}
