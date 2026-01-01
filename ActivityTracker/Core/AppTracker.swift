//
//  AppTracker.swift
//  ActivityTracker
//
//  核心追踪器
//  负责监控前台应用并记录使用分段
//

import Foundation
import AppKit
import Combine

/// 应用追踪器
/// 核心类，负责定时采样前台应用并管理使用分段
class AppTracker: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = AppTracker()
    
    // MARK: - Published Properties
    
    /// 是否正在追踪
    @Published var isTracking = false
    
    /// 当前前台应用名称
    @Published var currentApp: String = ""
    
    /// 当前前台应用的 Bundle ID
    @Published var currentBundleId: String = ""
    
    // MARK: - Private Properties
    
    /// 采样定时器
    private var timer: Timer?
    
    /// 当前正在记录的分段
    private var currentSegment: AppSegment?
    
    /// 数据存储引用
    private let dataStore = DataStore.shared
    
    /// 空闲检测器引用
    private let idleDetector = IdleDetector.shared
    
    /// 上一次采样的 Bundle ID（用于检测切换）
    private var lastBundleId: String?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 开始追踪
    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        
        // 创建采样定时器
        let interval = dataStore.settings.samplingInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sample()
        }
        
        // 启动相关服务
        startRelatedServices()
        
        // 立即执行一次采样
        sample()
    }
    
    /// 停止追踪
    func stopTracking() {
        guard isTracking else { return }
        isTracking = false
        
        // 停止定时器
        timer?.invalidate()
        timer = nil
        
        // 停止相关服务
        stopRelatedServices()
        
        // 关闭当前分段
        closeCurrentSegment()
    }
    
    /// 切换追踪状态
    func toggleTracking() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }
    
    // MARK: - Private Methods
    
    /// 启动相关服务
    private func startRelatedServices() {
        // 输入统计（参与度追踪）
        if dataStore.settings.enableInputStats {
            EngagementTracker.shared.start()
        }
        
        // 目标监控
        if dataStore.settings.enableGoals {
            GoalManager.shared.startMonitoring()
        }
        
        // 专注会话自动检测
        if dataStore.settings.enableFocusSessions {
            FocusSessionManager.shared.startAutoDetection()
        }
    }
    
    /// 停止相关服务
    private func stopRelatedServices() {
        EngagementTracker.shared.stop()
        GoalManager.shared.stopMonitoring()
        FocusSessionManager.shared.stopAutoDetection()
    }
    
    /// 关闭当前分段
    private func closeCurrentSegment() {
        if var segment = currentSegment {
            segment.endTime = Date()
            dataStore.updateLastSegment(endTime: segment.endTime)
            dataStore.saveTodayData()
            currentSegment = nil
        }
    }
    
    /// 执行一次采样
    private func sample() {
        let now = Date()
        let idleThreshold = dataStore.settings.idleThreshold
        
        // 检查是否空闲
        let isCurrentlyIdle = idleDetector.isIdle(threshold: idleThreshold)
        
        var bundleId: String
        var appName: String
        var windowTitle: String?
        
        if isCurrentlyIdle {
            // 空闲状态
            bundleId = AppSegment.idle
            appName = AppSegment.idleName
        } else if let frontApp = NSWorkspace.shared.frontmostApplication {
            // 获取前台应用信息
            bundleId = frontApp.bundleIdentifier ?? "unknown"
            appName = frontApp.localizedName ?? "Unknown"
            
            // 获取窗口标题（如果启用）
            if dataStore.settings.enableWindowTitle {
                windowTitle = getWindowTitle(for: frontApp)
            }
        } else {
            bundleId = "unknown"
            appName = "Unknown"
        }
        
        // 更新发布属性
        DispatchQueue.main.async {
            self.currentApp = appName
            self.currentBundleId = bundleId
        }
        
        // 记录应用切换
        if let last = lastBundleId, last != bundleId {
            dataStore.recordSwitch(from: last, to: bundleId)
        }
        lastBundleId = bundleId
        
        // 处理分段逻辑
        handleSegment(bundleId: bundleId, appName: appName, windowTitle: windowTitle, at: now)
    }
    
    /// 处理分段逻辑
    private func handleSegment(bundleId: String, appName: String, windowTitle: String?, at time: Date) {
        if let segment = currentSegment {
            if segment.bundleId == bundleId {
                // 同一应用，更新结束时间
                let engagementScore = dataStore.settings.enableEngagementScore
                    ? EngagementTracker.shared.currentScore
                    : nil
                dataStore.updateLastSegment(endTime: time, engagementScore: engagementScore)
            } else {
                // 应用切换，关闭旧分段，开始新分段
                dataStore.updateLastSegment(endTime: time)
                startNewSegment(bundleId: bundleId, appName: appName, windowTitle: windowTitle, at: time)
            }
        } else {
            // 没有当前分段，开始新分段
            startNewSegment(bundleId: bundleId, appName: appName, windowTitle: windowTitle, at: time)
        }
    }
    
    /// 开始新分段
    private func startNewSegment(bundleId: String, appName: String, windowTitle: String?, at time: Date) {
        var segment = AppSegment(
            startTime: time,
            endTime: time,
            bundleId: bundleId,
            appName: appName,
            windowTitle: windowTitle
        )
        segment.isIdle = bundleId == AppSegment.idle
        
        currentSegment = segment
        dataStore.addSegment(segment)
    }
    
    /// 获取窗口标题
    /// - Parameter app: 运行中的应用
    /// - Returns: 窗口标题，获取失败返回 nil
    /// - Note: 需要 Accessibility 权限
    private func getWindowTitle(for app: NSRunningApplication) -> String? {
        guard let pid = app.processIdentifier as pid_t? else { return nil }
        
        // 创建应用的 Accessibility 元素
        let appRef = AXUIElementCreateApplication(pid)
        var windowValue: CFTypeRef?
        
        // 获取焦点窗口
        guard AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowValue) == .success,
              let window = windowValue else { return nil }
        
        // 获取窗口标题
        var titleValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window as! AXUIElement, kAXTitleAttribute as CFString, &titleValue) == .success,
              let title = titleValue as? String else { return nil }
        
        return title
    }
}
