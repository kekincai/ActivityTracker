//
//  ProjectAndLabel.swift
//  ActivityTracker
//
//  项目和活动标签模型
//  用于自动分类用户的活动
//

import Foundation

// MARK: - 项目

/// 项目定义
/// 用于将应用使用自动归类到特定项目
struct Project: Codable, Identifiable, Hashable {
    
    /// 项目唯一标识符
    let id: String
    
    /// 项目名称
    var name: String
    
    /// 匹配规则列表
    var rules: [ProjectRule]
    
    /// 项目颜色（用于 UI 显示）
    var color: String?
    
    init(id: String = UUID().uuidString, name: String, rules: [ProjectRule] = [], color: String? = nil) {
        self.id = id
        self.name = name
        self.rules = rules
        self.color = color
    }
}

/// 项目匹配规则
/// 定义如何将应用使用归类到项目
struct ProjectRule: Codable, Hashable {
    
    /// 规则类型
    enum RuleType: String, Codable {
        /// 窗口标题正则匹配
        case windowTitleRegex
        
        /// Bundle ID 关键字匹配
        case bundleIdKeyword
        
        /// 文件路径前缀匹配
        case filePathPrefix
    }
    
    /// 规则类型
    let type: RuleType
    
    /// 匹配模式（正则表达式或关键字）
    let pattern: String
}

// MARK: - 活动标签

/// 活动标签定义
/// 用于将应用使用分类为不同的活动类型
struct ActivityLabel: Codable, Identifiable, Hashable {
    
    /// 标签唯一标识符
    let id: String
    
    /// 标签名称
    var name: String
    
    /// SF Symbol 图标名称
    var icon: String
    
    /// 标签颜色
    var color: String
    
    /// 匹配的 Bundle ID 列表
    var bundleIds: [String]
    
    /// 匹配的窗口标题关键字
    var titleKeywords: [String]
    
    /// 默认标签列表
    static let defaults: [ActivityLabel] = [
        ActivityLabel(
            id: "dev",
            name: "开发",
            icon: "hammer.fill",
            color: "blue",
            bundleIds: ["com.apple.dt.Xcode", "com.microsoft.VSCode", "com.jetbrains"],
            titleKeywords: ["code", "debug", "build"]
        ),
        ActivityLabel(
            id: "writing",
            name: "写作",
            icon: "doc.text.fill",
            color: "green",
            bundleIds: ["com.apple.Notes", "com.notion", "md.obsidian"],
            titleKeywords: ["doc", "note", "write"]
        ),
        ActivityLabel(
            id: "learning",
            name: "学习",
            icon: "book.fill",
            color: "purple",
            bundleIds: ["com.apple.Safari", "com.google.Chrome"],
            titleKeywords: ["course", "tutorial", "learn", "教程"]
        ),
        ActivityLabel(
            id: "meeting",
            name: "会议",
            icon: "video.fill",
            color: "orange",
            bundleIds: ["us.zoom.xos", "com.microsoft.teams", "com.slack"],
            titleKeywords: ["meeting", "call", "会议"]
        ),
        ActivityLabel(
            id: "entertainment",
            name: "娱乐",
            icon: "gamecontroller.fill",
            color: "red",
            bundleIds: ["com.spotify.client", "com.apple.Music", "com.netflix"],
            titleKeywords: ["youtube", "video", "game", "视频"]
        )
    ]
}

// MARK: - 目标

/// 使用目标定义
/// 用于设定每日/每周的使用时长目标
struct Goal: Codable, Identifiable {
    
    /// 唯一标识符
    let id: UUID
    
    /// 目标名称
    var name: String
    
    /// 统计周期类型
    var metricType: MetricType
    
    /// 目标分钟数
    var targetMinutes: Int
    
    /// 是否为上限（true = 不超过，false = 至少）
    var isUpperLimit: Bool
    
    /// 过滤类型
    var filterType: FilterType
    
    /// 过滤值（labelId / bundleId / projectId）
    var filterValue: String
    
    /// 是否启用
    var isEnabled: Bool = true
    
    /// 统计周期
    enum MetricType: String, Codable {
        case daily   // 每日
        case weekly  // 每周
    }
    
    /// 过滤类型
    enum FilterType: String, Codable {
        case label   // 按活动标签
        case app     // 按应用
        case project // 按项目
    }
    
    init(name: String, targetMinutes: Int, isUpperLimit: Bool, filterType: FilterType, filterValue: String) {
        self.id = UUID()
        self.name = name
        self.metricType = .daily
        self.targetMinutes = targetMinutes
        self.isUpperLimit = isUpperLimit
        self.filterType = filterType
        self.filterValue = filterValue
    }
}
