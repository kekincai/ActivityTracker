//
//  DailySummary.swift
//  ActivityTracker
//
//  每日汇总数据模型
//  包含一天内所有的追踪数据
//

import Foundation

/// 每日汇总
/// 存储一天内的所有追踪数据和统计信息
struct DailySummary: Codable {
    
    // MARK: - Properties
    
    /// 日期字符串（格式：yyyy-MM-dd）
    let date: String
    
    /// 当天所有的应用使用分段
    var segments: [AppSegment]
    
    /// 总活跃时间（不含空闲）
    var totalActiveTime: TimeInterval
    
    /// 总空闲时间
    var totalIdleTime: TimeInterval
    
    // MARK: - 扩展数据
    
    /// 每分钟输入统计（用于参与度计算）
    var minuteStats: [MinuteStats] = []
    
    /// 应用切换边（用于切换流分析）
    var switchEdges: [SwitchEdge] = []
    
    /// 手动标记的书签
    var bookmarks: [Bookmark] = []
    
    /// 专注会话列表
    var focusSessions: [FocusSession] = []
    
    // MARK: - Initialization
    
    init(date: String, segments: [AppSegment] = []) {
        self.date = date
        self.segments = segments
        self.totalActiveTime = 0
        self.totalIdleTime = 0
    }
    
    // MARK: - Methods
    
    /// 重新计算统计数据
    mutating func recalculate() {
        totalActiveTime = segments
            .filter { !$0.isIdle }
            .reduce(0) { $0 + $1.durationSeconds }
        
        totalIdleTime = segments
            .filter { $0.isIdle }
            .reduce(0) { $0 + $1.durationSeconds }
    }
    
    // MARK: - Computed Properties
    
    /// 上下文切换次数（应用切换次数）
    var contextSwitchCount: Int {
        guard segments.count > 1 else { return 0 }
        var count = 0
        for i in 1..<segments.count {
            if segments[i].bundleId != segments[i-1].bundleId {
                count += 1
            }
        }
        return count
    }
    
    /// 平均分段时长
    var averageSegmentDuration: TimeInterval {
        guard !segments.isEmpty else { return 0 }
        return segments.reduce(0) { $0 + $1.durationSeconds } / Double(segments.count)
    }
}
