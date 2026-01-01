//
//  FocusSessionManager.swift
//  ActivityTracker
//
//  专注会话管理器
//  管理手动和自动的专注会话
//

import Foundation

/// 专注会话管理器
/// 支持手动开始/结束专注会话，以及基于参与度的自动检测
class FocusSessionManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = FocusSessionManager()
    
    // MARK: - Published Properties
    
    /// 当前进行中的专注会话
    @Published var currentSession: FocusSession?
    
    /// 是否处于专注状态
    @Published var isInFocus: Bool = false
    
    // MARK: - Private Properties
    
    /// 自动检测定时器
    private var autoDetectTimer: Timer?
    
    /// 连续高参与度的分钟数
    private var consecutiveHighEngagement = 0
    
    /// 自动开始专注会话的阈值（连续高参与度分钟数）
    private let autoStartThreshold = 5
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Manual Control
    
    /// 手动开始专注会话
    /// - Parameter projectId: 关联的项目 ID（可选）
    func startManualSession(projectId: String? = nil) {
        guard currentSession == nil else { return }
        
        var session = FocusSession(isManual: true)
        session.projectId = projectId
        currentSession = session
        isInFocus = true
    }
    
    /// 结束当前专注会话
    func endSession() {
        guard var session = currentSession else { return }
        session.endTime = Date()
        
        // 保存到 DataStore
        DataStore.shared.addFocusSession(session)
        
        currentSession = nil
        isInFocus = false
        consecutiveHighEngagement = 0
    }
    
    // MARK: - Auto Detection
    
    /// 开始自动检测
    /// - Note: 需要启用参与度评分功能
    func startAutoDetection() {
        guard DataStore.shared.settings.enableFocusSessions,
              DataStore.shared.settings.enableEngagementScore else { return }
        
        // 每分钟检查一次参与度
        autoDetectTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkEngagement()
        }
    }
    
    /// 停止自动检测
    func stopAutoDetection() {
        autoDetectTimer?.invalidate()
        autoDetectTimer = nil
    }
    
    /// 检查参与度并决定是否自动开始/结束会话
    private func checkEngagement() {
        let engagement = EngagementTracker.shared
        
        if engagement.currentMode == .focus {
            consecutiveHighEngagement += 1
            
            // 连续高参与度达到阈值，自动开始专注会话
            if consecutiveHighEngagement >= autoStartThreshold && currentSession == nil {
                var session = FocusSession(isManual: false)
                // 回溯开始时间到高参与度开始的时刻
                session.startTime = Date().addingTimeInterval(-Double(autoStartThreshold) * 60)
                currentSession = session
                isInFocus = true
            }
        } else {
            // 参与度下降
            if currentSession != nil && !currentSession!.isManual {
                // 自动会话：参与度持续下降则结束
                if consecutiveHighEngagement < 2 {
                    endSession()
                }
            }
            consecutiveHighEngagement = max(0, consecutiveHighEngagement - 1)
        }
    }
    
    // MARK: - Statistics
    
    /// 今日专注总时长
    func todayFocusTime() -> TimeInterval {
        DataStore.shared.todaySummary.focusSessions.reduce(0) { $0 + $1.durationSeconds }
    }
    
    /// 今日专注会话数量
    func todaySessionCount() -> Int {
        DataStore.shared.todaySummary.focusSessions.count
    }
}
