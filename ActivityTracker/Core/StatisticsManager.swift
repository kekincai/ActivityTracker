//
//  StatisticsManager.swift
//  ActivityTracker
//
//  统计管理器
//  负责计算和汇总各类统计数据
//

import Foundation
import AppKit

/// 统计管理器
/// 计算应用使用统计、标签统计、项目统计等
class StatisticsManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = StatisticsManager()
    
    // MARK: - Published Properties
    
    /// 应用使用排行榜
    @Published var topApps: [AppStatistics] = []
    
    /// 总活跃时间
    @Published var totalActiveTime: TimeInterval = 0
    
    /// 总空闲时间
    @Published var totalIdleTime: TimeInterval = 0
    
    /// 按标签分组的时长统计
    @Published var labelStats: [String: TimeInterval] = [:]
    
    /// 按项目分组的时长统计
    @Published var projectStats: [String: TimeInterval] = [:]
    
    // MARK: - Private Properties
    
    private let dataStore = DataStore.shared
    
    // MARK: - Initialization
    
    private init() {
        refresh()
    }
    
    // MARK: - Public Methods
    
    /// 刷新统计数据
    func refresh() {
        dataStore.loadTodayData()
        calculateStatistics()
    }
    
    /// 获取指定标签的使用时长
    func durationForLabel(_ labelId: String) -> TimeInterval {
        labelStats[labelId] ?? 0
    }
    
    /// 获取指定项目的使用时长
    func durationForProject(_ projectId: String) -> TimeInterval {
        projectStats[projectId] ?? 0
    }
    
    // MARK: - Private Methods
    
    /// 计算统计数据
    private func calculateStatistics() {
        let segments = dataStore.todaySummary.segments
        
        // 计算总时长
        totalActiveTime = segments
            .filter { !$0.isIdle }
            .reduce(0) { $0 + $1.durationSeconds }
        
        totalIdleTime = segments
            .filter { $0.isIdle }
            .reduce(0) { $0 + $1.durationSeconds }
        
        // 按应用分组统计
        var appDurations: [String: (name: String, duration: TimeInterval, labelId: String?)] = [:]
        
        for segment in segments where !segment.isIdle {
            if var existing = appDurations[segment.bundleId] {
                existing.duration += segment.durationSeconds
                appDurations[segment.bundleId] = existing
            } else {
                appDurations[segment.bundleId] = (segment.appName, segment.durationSeconds, segment.labelId)
            }
        }
        
        // 生成排行榜
        topApps = appDurations.map { bundleId, info in
            var stats = AppStatistics(
                bundleId: bundleId,
                appName: info.name,
                totalDuration: info.duration,
                labelId: info.labelId
            )
            stats.icon = getAppIcon(bundleId: bundleId)
            return stats
        }
        .sorted { $0.totalDuration > $1.totalDuration }
        .prefix(10)
        .map { $0 }
        
        // 按标签分组统计
        labelStats = [:]
        for segment in segments where !segment.isIdle {
            let label = segment.labelId ?? "未分类"
            labelStats[label, default: 0] += segment.durationSeconds
        }
        
        // 按项目分组统计
        projectStats = [:]
        for segment in segments where !segment.isIdle {
            let project = segment.projectId ?? "未分类"
            projectStats[project, default: 0] += segment.durationSeconds
        }
    }
    
    /// 获取应用图标
    private func getAppIcon(bundleId: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
