//
//  SwitchAnalyzer.swift
//  ActivityTracker
//
//  切换分析器
//  分析应用切换模式和碎片化程度
//

import Foundation

/// 切换分析器
/// 统计应用切换流和碎片化指数
class SwitchAnalyzer: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = SwitchAnalyzer()
    
    // MARK: - Published Properties
    
    /// 切换边列表（用于 Sankey 图）
    @Published var switchEdges: [SwitchEdge] = []
    
    /// 上下文切换次数
    @Published var contextSwitchCount: Int = 0
    
    /// 平均分段时长
    @Published var averageSegmentDuration: TimeInterval = 0
    
    /// 最常打断你的应用（Top Interrupters）
    @Published var topInterrupters: [(bundleId: String, appName: String, count: Int)] = []
    
    /// 碎片化指数（0-100，越高越碎片化）
    @Published var fragmentationIndex: Double = 0
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Analysis
    
    /// 执行分析
    func analyze() {
        let segments = DataStore.shared.todaySummary.segments
        
        guard segments.count > 1 else {
            reset()
            return
        }
        
        // 统计切换边
        var edgeMap: [String: SwitchEdge] = [:]
        var interrupterCount: [String: (name: String, count: Int)] = [:]
        var switchCount = 0
        
        for i in 1..<segments.count {
            let from = segments[i-1]
            let to = segments[i]
            
            // 跳过同一应用
            guard from.bundleId != to.bundleId else { continue }
            
            switchCount += 1
            
            // 记录切换边
            let key = "\(from.bundleId)->\(to.bundleId)"
            if var edge = edgeMap[key] {
                edge.count += 1
                edge.totalDuration += to.durationSeconds
                edgeMap[key] = edge
            } else {
                var edge = SwitchEdge(from: from.bundleId, to: to.bundleId)
                edge.totalDuration = to.durationSeconds
                edgeMap[key] = edge
            }
            
            // 记录打断者
            if let existing = interrupterCount[to.bundleId] {
                interrupterCount[to.bundleId] = (existing.name, existing.count + 1)
            } else {
                interrupterCount[to.bundleId] = (to.appName, 1)
            }
        }
        
        // 更新发布属性
        DispatchQueue.main.async {
            self.switchEdges = Array(edgeMap.values).sorted { $0.count > $1.count }
            self.contextSwitchCount = switchCount
            
            // 计算平均分段时长
            let totalDuration = segments.reduce(0) { $0 + $1.durationSeconds }
            self.averageSegmentDuration = totalDuration / Double(segments.count)
            
            // 排序打断者
            self.topInterrupters = interrupterCount
                .map { ($0.key, $0.value.name, $0.value.count) }
                .sorted { $0.2 > $1.2 }
                .prefix(5)
                .map { $0 }
            
            // 计算碎片化指数
            // 公式：切换次数 / 总时长(小时) * 权重
            let hours = max(totalDuration / 3600, 0.1)
            self.fragmentationIndex = min(100, Double(switchCount) / hours * 2)
        }
    }
    
    /// 重置所有统计
    private func reset() {
        switchEdges = []
        contextSwitchCount = 0
        averageSegmentDuration = 0
        topInterrupters = []
        fragmentationIndex = 0
    }
    
    /// 获取每小时切换次数
    /// - Returns: (小时, 切换次数) 数组
    func switchesPerHour() -> [(hour: Int, count: Int)] {
        let segments = DataStore.shared.todaySummary.segments
        var hourlyCount: [Int: Int] = [:]
        
        for i in 1..<segments.count {
            if segments[i].bundleId != segments[i-1].bundleId {
                let hour = Calendar.current.component(.hour, from: segments[i].startTime)
                hourlyCount[hour, default: 0] += 1
            }
        }
        
        return (0..<24).map { ($0, hourlyCount[$0] ?? 0) }
    }
}
