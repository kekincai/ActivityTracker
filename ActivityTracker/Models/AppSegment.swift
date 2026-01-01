//
//  AppSegment.swift
//  ActivityTracker
//
//  应用使用分段模型
//  记录用户在某个时间段内使用某个应用的信息
//

import Foundation

/// 应用使用分段
/// 表示用户连续使用同一个应用的时间段
struct AppSegment: Identifiable, Codable, Equatable {
    
    // MARK: - Properties
    
    /// 唯一标识符
    let id: UUID
    
    /// 分段开始时间
    var startTime: Date
    
    /// 分段结束时间
    var endTime: Date
    
    /// 应用的 Bundle ID（如 com.apple.Safari）
    let bundleId: String
    
    /// 应用显示名称
    let appName: String
    
    /// 窗口标题（可选，需要 Accessibility 权限）
    var windowTitle: String?
    
    // MARK: - 扩展属性（用于行为分析）
    
    /// 活动标签 ID（如 dev/writing/learning）
    var labelId: String?
    
    /// 关联的项目 ID
    var projectId: String?
    
    /// 是否为空闲状态
    var isIdle: Bool = false
    
    /// 参与度评分（0-100）
    var engagementScore: Int?
    
    /// 是否为会议/通话
    var isMeeting: Bool = false
    
    // MARK: - Computed Properties
    
    /// 分段持续时间（秒）
    var durationSeconds: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date = Date(),
        bundleId: String,
        appName: String,
        windowTitle: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.bundleId = bundleId
        self.appName = appName
        self.windowTitle = windowTitle
        self.isIdle = bundleId == AppSegment.idle
    }
    
    // MARK: - Constants
    
    /// 空闲状态的 Bundle ID
    static let idle = "idle"
    
    /// 空闲状态的显示名称
    static let idleName = "Idle"
}
