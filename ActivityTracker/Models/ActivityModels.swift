//
//  ActivityModels.swift
//  ActivityTracker
//
//  活动相关的数据模型
//  包括输入统计、切换边、书签、专注会话等
//

import Foundation

// MARK: - 每分钟输入统计

/// 每分钟的输入活动统计
/// 用于计算用户的参与度（Engagement Score）
struct MinuteStats: Codable, Identifiable {
    
    /// 唯一标识符
    let id: UUID
    
    /// 这一分钟的开始时间
    let minuteStartTime: Date
    
    /// 按键次数
    var keyDownCount: Int = 0
    
    /// 鼠标点击次数
    var mouseClickCount: Int = 0
    
    /// 滚动次数
    var scrollCount: Int = 0
    
    /// 鼠标移动距离（像素）
    var mouseMoveDistance: Double = 0
    
    init(minuteStartTime: Date) {
        self.id = UUID()
        self.minuteStartTime = minuteStartTime
    }
    
    /// 总活动量
    var totalActivity: Int {
        keyDownCount + mouseClickCount + scrollCount
    }
}

// MARK: - 应用切换边

/// 应用切换记录
/// 用于分析用户的应用切换模式（Sankey 图/切换流）
struct SwitchEdge: Codable, Identifiable {
    
    /// 唯一标识符
    let id: UUID
    
    /// 切换前的应用 Bundle ID
    let fromBundleId: String
    
    /// 切换后的应用 Bundle ID
    let toBundleId: String
    
    /// 切换次数
    var count: Int = 1
    
    /// 在目标应用停留的总时长
    var totalDuration: TimeInterval = 0
    
    init(from: String, to: String) {
        self.id = UUID()
        self.fromBundleId = from
        self.toBundleId = to
    }
}

// MARK: - 书签（手动事件标记）

/// 用户手动添加的事件标记
/// 用于在时间轴上标记重要时刻
struct Bookmark: Codable, Identifiable {
    
    /// 唯一标识符
    let id: UUID
    
    /// 标记时间
    let time: Date
    
    /// 标记文本
    var text: String
    
    /// 颜色标签（如 blue/green/orange）
    var colorTag: String?
    
    init(time: Date = Date(), text: String, colorTag: String? = nil) {
        self.id = UUID()
        self.time = time
        self.text = text
        self.colorTag = colorTag
    }
}

// MARK: - 专注会话

/// 专注会话记录
/// 可以手动开始/结束，也可以根据参与度自动检测
struct FocusSession: Codable, Identifiable {
    
    /// 唯一标识符
    let id: UUID
    
    /// 会话开始时间
    var startTime: Date
    
    /// 会话结束时间（nil 表示进行中）
    var endTime: Date?
    
    /// 关联的项目 ID
    var projectId: String?
    
    /// 是否为手动开始（false 表示自动检测）
    var isManual: Bool = true
    
    /// 会话持续时间（秒）
    var durationSeconds: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    init(startTime: Date = Date(), isManual: Bool = true) {
        self.id = UUID()
        self.startTime = startTime
        self.isManual = isManual
    }
}

// MARK: - 参与度模式

/// 用户参与度模式
/// 根据输入活动量判断用户的专注程度
enum EngagementMode: String, Codable {
    /// 专注模式（高活动量）
    case focus = "Focus"
    
    /// 轻度使用（中等活动量）
    case light = "Light"
    
    /// 被动模式（低活动量，如看视频）
    case passive = "Passive"
    
    /// 根据参与度分数判断模式
    static func from(score: Int) -> EngagementMode {
        if score >= 70 { return .focus }
        if score >= 30 { return .light }
        return .passive
    }
}
