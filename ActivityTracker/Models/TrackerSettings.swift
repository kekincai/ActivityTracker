//
//  TrackerSettings.swift
//  ActivityTracker
//
//  应用设置模型
//  存储所有可配置的选项
//

import Foundation

/// 追踪器设置
/// 包含所有可配置的选项
struct TrackerSettings: Codable {
    
    // MARK: - 基础设置
    
    /// 采样间隔（秒），范围 0.5-5.0
    var samplingInterval: Double = 1.0
    
    /// 空闲判定阈值（秒），默认 5 分钟
    var idleThreshold: Double = 300.0
    
    /// 是否启用窗口标题获取（需要 Accessibility 权限）
    var enableWindowTitle: Bool = false
    
    /// 数据保留天数
    var dataRetentionDays: Int = 90
    
    /// 是否开机启动
    var launchAtLogin: Bool = false
    
    // MARK: - 功能开关
    
    /// 启用项目自动识别
    var enableProjectDetection: Bool = true
    
    /// 启用活动标签自动分类
    var enableActivityLabels: Bool = true
    
    /// 启用会议自动检测
    var enableMeetingDetection: Bool = true
    
    /// 启用参与度评分（需要 Accessibility 权限）
    var enableEngagementScore: Bool = false
    
    /// 启用输入统计（需要 Accessibility 权限）
    var enableInputStats: Bool = false
    
    /// 启用目标提醒
    var enableGoals: Bool = false
    
    /// 启用专注会话
    var enableFocusSessions: Bool = true
    
    /// 启用数据脱敏
    var enableDataRedaction: Bool = false
    
    // MARK: - 过滤设置
    
    /// 黑名单应用（不追踪这些应用）
    var blacklistedBundleIds: [String] = []
    
    /// 是否启用白名单模式（只追踪白名单中的应用）
    var whitelistMode: Bool = false
    
    /// 白名单应用
    var whitelistedBundleIds: [String] = []
    
    // MARK: - 脱敏规则
    
    /// 脱敏正则表达式列表
    var redactionPatterns: [String] = [
        // 邮箱地址
        "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
        // Token 类字符串（32位以上的字母数字串）
        "\\b[A-Za-z0-9]{32,}\\b"
    ]
    
    /// 默认设置
    static let `default` = TrackerSettings()
}
