//
//  MeetingDetector.swift
//  ActivityTracker
//
//  会议检测器
//  自动识别用户是否在进行会议或通话
//

import Foundation

/// 会议检测器
/// 根据应用 Bundle ID 和窗口标题判断是否在开会
class MeetingDetector {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = MeetingDetector()
    
    // MARK: - Constants
    
    /// 会议应用 Bundle ID 白名单
    private let meetingBundleIds: Set<String> = [
        "us.zoom.xos",                                      // Zoom
        "com.microsoft.teams",                              // Microsoft Teams
        "com.google.Chrome.app.kjgfgldnnfoeklkmfkjfagphfepbbdan", // Google Meet PWA
        "com.slack",                                        // Slack
        "com.discord",                                      // Discord
        "com.skype.skype",                                  // Skype
        "com.webex.meetingmanager",                         // Webex
        "com.facetime",                                     // FaceTime
        "com.apple.FaceTime"                                // FaceTime (另一个 ID)
    ]
    
    /// 会议相关关键字
    private let meetingKeywords: [String] = [
        "meeting", "call", "会议", "通話", "会議", "webinar",
        "huddle", "standup", "sync", "1:1", "interview",
        "conference", "video chat"
    ]
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Detection
    
    /// 检测是否为会议
    /// - Parameters:
    ///   - bundleId: 应用的 Bundle ID
    ///   - windowTitle: 窗口标题（可选）
    /// - Returns: 是否为会议
    func isMeeting(bundleId: String, windowTitle: String?) -> Bool {
        guard DataStore.shared.settings.enableMeetingDetection else { return false }
        
        // 检查 Bundle ID
        let normalizedBundleId = bundleId.lowercased()
        for meetingId in meetingBundleIds {
            if normalizedBundleId.contains(meetingId.lowercased()) {
                return true
            }
        }
        
        // 检查窗口标题
        if let title = windowTitle?.lowercased() {
            for keyword in meetingKeywords {
                if title.contains(keyword.lowercased()) {
                    return true
                }
            }
        }
        
        return false
    }
}
