//
//  EngagementTracker.swift
//  ActivityTracker
//
//  参与度追踪器
//  通过监控输入活动来计算用户的参与度评分
//

import Foundation
import Cocoa

/// 参与度追踪器
/// 监控键盘、鼠标活动，计算用户的参与度（Engagement Score）
/// - Note: 需要 Accessibility 权限
class EngagementTracker: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = EngagementTracker()
    
    // MARK: - Published Properties
    
    /// 当前参与度评分（0-100）
    @Published var currentScore: Int = 0
    
    /// 当前参与度模式
    @Published var currentMode: EngagementMode = .passive
    
    /// 当前分钟的统计数据
    @Published var currentMinuteStats: MinuteStats?
    
    // MARK: - Private Properties
    
    /// 全局事件监听器
    private var eventMonitor: Any?
    
    /// 当前分钟的开始时间
    private var lastMinuteStart: Date?
    
    /// 按键计数
    private var keyCount = 0
    
    /// 点击计数
    private var clickCount = 0
    
    /// 滚动计数
    private var scrollCount = 0
    
    /// 上一次鼠标位置
    private var lastMouseLocation: NSPoint?
    
    /// 鼠标移动距离
    private var mouseDistance: Double = 0
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 开始追踪
    /// - Note: 需要 Accessibility 权限
    func start() {
        guard DataStore.shared.settings.enableInputStats else { return }
        
        lastMinuteStart = Date()
        resetCounters()
        
        // 监听全局事件
        let mask: NSEvent.EventTypeMask = [
            .keyDown,
            .leftMouseDown,
            .rightMouseDown,
            .scrollWheel,
            .mouseMoved
        ]
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleEvent(event)
        }
        
        // 每分钟汇总一次
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.summarizeMinute()
        }
    }
    
    /// 停止追踪
    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    /// 检查 Accessibility 权限
    /// - Returns: 是否有权限
    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - Private Methods
    
    /// 处理输入事件
    private func handleEvent(_ event: NSEvent) {
        switch event.type {
        case .keyDown:
            keyCount += 1
        case .leftMouseDown, .rightMouseDown:
            clickCount += 1
        case .scrollWheel:
            scrollCount += 1
        case .mouseMoved:
            // 计算鼠标移动距离
            let location = event.locationInWindow
            if let last = lastMouseLocation {
                let dx = location.x - last.x
                let dy = location.y - last.y
                mouseDistance += sqrt(dx*dx + dy*dy)
            }
            lastMouseLocation = location
        default:
            break
        }
        
        updateScore()
    }
    
    /// 更新参与度评分
    private func updateScore() {
        // 简单算法：基于活动量计算分数
        // 按键权重最高，点击次之，滚动最低
        let activitySum = keyCount + clickCount * 2 + scrollCount
        let score = min(100, activitySum * 2)
        
        DispatchQueue.main.async {
            self.currentScore = score
            self.currentMode = EngagementMode.from(score: score)
        }
    }
    
    /// 汇总当前分钟的统计数据
    private func summarizeMinute() {
        guard let start = lastMinuteStart else { return }
        
        // 创建统计数据
        var stats = MinuteStats(minuteStartTime: start)
        stats.keyDownCount = keyCount
        stats.mouseClickCount = clickCount
        stats.scrollCount = scrollCount
        stats.mouseMoveDistance = mouseDistance
        
        DispatchQueue.main.async {
            self.currentMinuteStats = stats
        }
        
        // 保存到 DataStore
        DataStore.shared.addMinuteStats(stats)
        
        // 重置计数器
        lastMinuteStart = Date()
        resetCounters()
    }
    
    /// 重置计数器
    private func resetCounters() {
        keyCount = 0
        clickCount = 0
        scrollCount = 0
        mouseDistance = 0
        lastMouseLocation = nil
    }
}
