//
//  AppStatistics.swift
//  ActivityTracker
//
//  应用统计数据模型
//  用于展示应用使用排行榜
//

import Foundation
import AppKit

/// 应用统计数据
/// 汇总某个应用的使用时长和相关信息
struct AppStatistics: Identifiable {
    
    /// 唯一标识符
    let id = UUID()
    
    /// 应用的 Bundle ID
    let bundleId: String
    
    /// 应用显示名称
    let appName: String
    
    /// 总使用时长（秒）
    var totalDuration: TimeInterval
    
    /// 应用图标
    var icon: NSImage?
    
    /// 关联的活动标签 ID
    var labelId: String?
    
    /// 格式化的时长字符串
    var formattedDuration: String {
        formatDuration(totalDuration)
    }
}
