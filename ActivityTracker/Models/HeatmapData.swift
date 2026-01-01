//
//  HeatmapData.swift
//  ActivityTracker
//
//  热力图数据模型和生成器
//  用于可视化每周/每天的活动分布
//

import Foundation

// MARK: - 热力图单元格

/// 热力图单元格数据
/// 表示某一天某一小时的活动数据
struct HeatmapCell: Identifiable {
    
    /// 唯一标识符
    let id = UUID()
    
    /// 星期几（0-6，周日到周六）
    let dayOfWeek: Int
    
    /// 小时（0-23）
    let hour: Int
    
    /// 归一化的活跃度值（0-1）
    var value: Double
    
    /// 实际活跃分钟数
    var minutes: Int
}

// MARK: - 热力图生成器

/// 热力图数据生成器
/// 根据历史数据生成热力图所需的数据
class HeatmapGenerator: ObservableObject {
    
    /// 单例
    static let shared = HeatmapGenerator()
    
    /// 热力图单元格数据
    @Published var cells: [HeatmapCell] = []
    
    /// 最大值（用于归一化）
    @Published var maxValue: Double = 0
    
    private init() {}
    
    /// 热力图类型
    enum HeatmapType {
        /// 活跃时间
        case active
        
        /// 空闲时间
        case idle
        
        /// 专注时间
        case focus
        
        /// 参与度
        case engagement
    }
    
    /// 生成热力图数据
    /// - Parameters:
    ///   - type: 热力图类型
    ///   - days: 统计天数
    func generate(type: HeatmapType = .active, days: Int = 7) {
        // 初始化 7x24 的分钟数矩阵
        var cellMinutes: [[Int]] = Array(repeating: Array(repeating: 0, count: 24), count: 7)
        
        let calendar = Calendar.current
        let today = Date()
        
        // 收集过去 N 天的数据
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dateStr = dateString(from: date)
            let dayOfWeek = calendar.component(.weekday, from: date) - 1  // 转换为 0-6
            
            // 加载该天的数据
            let summary = DataStore.shared.loadSummary(for: dateStr)
            
            // 遍历所有分段
            for segment in summary.segments {
                let hour = calendar.component(.hour, from: segment.startTime)
                let minutes = Int(segment.durationSeconds / 60)
                
                // 根据类型判断是否计入
                let shouldCount: Bool
                switch type {
                case .active:
                    shouldCount = !segment.isIdle
                case .idle:
                    shouldCount = segment.isIdle
                case .focus:
                    shouldCount = segment.engagementScore ?? 0 >= 70
                case .engagement:
                    shouldCount = true
                }
                
                if shouldCount {
                    cellMinutes[dayOfWeek][hour] += minutes
                }
            }
        }
        
        // 找出最大值用于归一化
        let maxMinutes = cellMinutes.flatMap { $0 }.max() ?? 1
        
        // 生成单元格数据
        var result: [HeatmapCell] = []
        for day in 0..<7 {
            for hour in 0..<24 {
                let value = Double(cellMinutes[day][hour]) / Double(max(maxMinutes, 1))
                result.append(HeatmapCell(
                    dayOfWeek: day,
                    hour: hour,
                    value: value,
                    minutes: cellMinutes[day][hour]
                ))
            }
        }
        
        // 更新发布属性
        DispatchQueue.main.async {
            self.cells = result
            self.maxValue = Double(maxMinutes)
        }
    }
}
