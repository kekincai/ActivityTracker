//
//  GoalManager.swift
//  ActivityTracker
//
//  目标管理器
//  管理使用时长目标并在达成/超限时发送提醒
//

import Foundation
import UserNotifications

/// 目标管理器
/// 设定和监控使用时长目标，支持通知提醒
class GoalManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = GoalManager()
    
    // MARK: - Published Properties
    
    /// 目标列表
    @Published var goals: [Goal] = []
    
    /// 目标进度（goalId -> 进度 0~1）
    @Published var goalProgress: [UUID: Double] = [:]
    
    // MARK: - Private Properties
    
    /// 检查定时器
    private var checkTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        loadGoals()
        requestNotificationPermission()
    }
    
    // MARK: - Monitoring
    
    /// 开始监控目标
    func startMonitoring() {
        guard DataStore.shared.settings.enableGoals else { return }
        
        // 每分钟检查一次
        checkTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkGoals()
        }
        checkGoals()
    }
    
    /// 停止监控
    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    /// 检查所有目标
    func checkGoals() {
        let stats = StatisticsManager.shared
        stats.refresh()
        
        for goal in goals where goal.isEnabled {
            let currentMinutes = calculateCurrentMinutes(for: goal)
            let progress = Double(currentMinutes) / Double(goal.targetMinutes)
            
            DispatchQueue.main.async {
                self.goalProgress[goal.id] = progress
            }
            
            // 检查是否需要提醒
            if goal.isUpperLimit && currentMinutes >= goal.targetMinutes {
                // 超过上限
                sendNotification(goal: goal, currentMinutes: currentMinutes, exceeded: true)
            } else if !goal.isUpperLimit && progress >= 0.9 && progress < 1.0 {
                // 快达成目标（90%）
                sendNotification(goal: goal, currentMinutes: currentMinutes, exceeded: false)
            }
        }
    }
    
    /// 计算目标当前的使用分钟数
    private func calculateCurrentMinutes(for goal: Goal) -> Int {
        let segments = DataStore.shared.todaySummary.segments
        
        let filteredDuration: TimeInterval
        switch goal.filterType {
        case .label:
            filteredDuration = segments
                .filter { $0.labelId == goal.filterValue }
                .reduce(0) { $0 + $1.durationSeconds }
        case .app:
            filteredDuration = segments
                .filter { $0.bundleId == goal.filterValue }
                .reduce(0) { $0 + $1.durationSeconds }
        case .project:
            filteredDuration = segments
                .filter { $0.projectId == goal.filterValue }
                .reduce(0) { $0 + $1.durationSeconds }
        }
        
        return Int(filteredDuration / 60)
    }
    
    // MARK: - Notifications
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    /// 发送通知
    private func sendNotification(goal: Goal, currentMinutes: Int, exceeded: Bool) {
        let content = UNMutableNotificationContent()
        
        if exceeded {
            content.title = "⚠️ 目标超限"
            content.body = "\(goal.name): 已使用 \(currentMinutes) 分钟，超过目标 \(goal.targetMinutes) 分钟"
        } else {
            content.title = "🎯 即将达成目标"
            content.body = "\(goal.name): 已使用 \(currentMinutes) 分钟，目标 \(goal.targetMinutes) 分钟"
        }
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: goal.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Goal Management
    
    /// 添加目标
    func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveGoals()
    }
    
    /// 删除目标
    func removeGoal(id: UUID) {
        goals.removeAll { $0.id == id }
        saveGoals()
    }
    
    /// 更新目标
    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
        }
    }
    
    // MARK: - Persistence
    
    /// 目标文件路径
    private var goalsFilePath: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("ActivityTracker/goals.json")
    }
    
    /// 加载目标
    private func loadGoals() {
        guard FileManager.default.fileExists(atPath: goalsFilePath.path) else { return }
        
        do {
            let data = try Data(contentsOf: goalsFilePath)
            goals = try JSONDecoder().decode([Goal].self, from: data)
        } catch {
            print("Failed to load goals: \(error)")
        }
    }
    
    /// 保存目标
    private func saveGoals() {
        do {
            let data = try JSONEncoder().encode(goals)
            try data.write(to: goalsFilePath)
        } catch {
            print("Failed to save goals: \(error)")
        }
    }
}
