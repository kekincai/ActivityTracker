//
//  Helpers.swift
//  ActivityTracker
//
//  通用工具函数
//  提供格式化、日期处理等辅助功能
//

import Foundation

// MARK: - 时间格式化

/// 将秒数格式化为可读的时长字符串
/// - Parameter seconds: 秒数
/// - Returns: 格式化的字符串（如 "2h 30m" 或 "45m 20s"）
func formatDuration(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    let secs = Int(seconds) % 60
    
    if hours > 0 {
        return String(format: "%dh %dm", hours, minutes)
    } else if minutes > 0 {
        return String(format: "%dm %ds", minutes, secs)
    } else {
        return String(format: "%ds", secs)
    }
}

// MARK: - 日期格式化

/// 将日期转换为日期字符串
/// - Parameter date: 日期对象，默认为当前时间
/// - Returns: 格式化的日期字符串（yyyy-MM-dd）
func dateString(from date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

/// 将日期转换为时间字符串
/// - Parameter date: 日期对象
/// - Returns: 格式化的时间字符串（HH:mm:ss）
func timeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: date)
}

/// 将日期转换为简短时间字符串
/// - Parameter date: 日期对象
/// - Returns: 格式化的时间字符串（HH:mm）
func shortTimeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}
