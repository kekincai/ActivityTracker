//
//  DataStore.swift
//  ActivityTracker
//
//  数据存储管理器
//  负责数据的持久化、加载和管理
//

import Foundation

/// 数据存储管理器
/// 管理所有追踪数据的存储和读取
class DataStore: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = DataStore()
    
    // MARK: - Properties
    
    /// 文件管理器
    private let fileManager = FileManager.default
    
    /// 数据存储目录
    private var dataDirectory: URL
    
    /// 今日汇总数据
    @Published var todaySummary: DailySummary
    
    /// 应用设置
    @Published var settings: TrackerSettings
    
    // MARK: - Initialization
    
    private init() {
        // 设置数据目录
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        dataDirectory = appSupport.appendingPathComponent("ActivityTracker", isDirectory: true)
        
        // 创建目录（如果不存在）
        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        
        // 初始化今日数据
        let today = dateString()
        todaySummary = DailySummary(date: today)
        settings = TrackerSettings.default
        
        // 加载数据
        loadTodayData()
        loadSettings()
        
        // 清理过期数据
        cleanupOldData()
    }
    
    // MARK: - File Paths
    
    /// 获取指定日期的数据文件路径
    private func dataFilePath(for date: String) -> URL {
        dataDirectory.appendingPathComponent("segments_\(date).json")
    }
    
    /// 设置文件路径
    private var settingsFilePath: URL {
        dataDirectory.appendingPathComponent("settings.json")
    }
    
    // MARK: - Load Data
    
    /// 加载今日数据
    func loadTodayData() {
        let today = dateString()
        todaySummary = loadSummary(for: today)
    }
    
    /// 加载指定日期的汇总数据
    /// - Parameter date: 日期字符串（yyyy-MM-dd）
    /// - Returns: 每日汇总数据
    func loadSummary(for date: String) -> DailySummary {
        let filePath = dataFilePath(for: date)
        
        guard fileManager.fileExists(atPath: filePath.path) else {
            return DailySummary(date: date)
        }
        
        do {
            let data = try Data(contentsOf: filePath)
            return try JSONDecoder().decode(DailySummary.self, from: data)
        } catch {
            print("Failed to load data for \(date): \(error)")
            return DailySummary(date: date)
        }
    }
    
    /// 加载设置
    func loadSettings() {
        guard fileManager.fileExists(atPath: settingsFilePath.path) else { return }
        
        do {
            let data = try Data(contentsOf: settingsFilePath)
            settings = try JSONDecoder().decode(TrackerSettings.self, from: data)
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    // MARK: - Save Data
    
    /// 保存今日数据
    func saveTodayData() {
        let filePath = dataFilePath(for: todaySummary.date)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(todaySummary)
            try data.write(to: filePath)
        } catch {
            print("Failed to save data: \(error)")
        }
    }
    
    /// 保存设置
    func saveSettings() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settings)
            try data.write(to: settingsFilePath)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    // MARK: - Segment Management
    
    /// 添加新分段
    /// - Parameter segment: 应用使用分段
    func addSegment(_ segment: AppSegment) {
        checkDayChange()
        
        // 应用黑名单过滤
        if shouldFilter(bundleId: segment.bundleId) { return }
        
        // 处理分段数据
        var processedSegment = segment
        
        // 应用数据脱敏
        processedSegment.windowTitle = DataRedactor.shared.redact(segment.windowTitle)
        
        // 自动标签分类
        processedSegment.labelId = ActivityLabeler.shared.detectLabel(for: segment)
        
        // 自动项目识别
        let (projectId, _) = ProjectDetector.shared.detectProject(for: segment)
        processedSegment.projectId = projectId
        
        // 会议检测
        processedSegment.isMeeting = MeetingDetector.shared.isMeeting(
            bundleId: segment.bundleId,
            windowTitle: segment.windowTitle
        )
        
        // 添加到今日数据
        todaySummary.segments.append(processedSegment)
        todaySummary.recalculate()
        saveTodayData()
    }
    
    /// 更新最后一个分段的结束时间
    /// - Parameters:
    ///   - endTime: 新的结束时间
    ///   - engagementScore: 参与度评分（可选）
    func updateLastSegment(endTime: Date, engagementScore: Int? = nil) {
        guard !todaySummary.segments.isEmpty else { return }
        
        todaySummary.segments[todaySummary.segments.count - 1].endTime = endTime
        
        if let score = engagementScore {
            todaySummary.segments[todaySummary.segments.count - 1].engagementScore = score
        }
        
        todaySummary.recalculate()
    }
    
    // MARK: - Minute Stats
    
    /// 添加每分钟统计
    func addMinuteStats(_ stats: MinuteStats) {
        checkDayChange()
        todaySummary.minuteStats.append(stats)
        saveTodayData()
    }
    
    // MARK: - Switch Edges
    
    /// 记录应用切换
    func recordSwitch(from: String, to: String) {
        checkDayChange()
        
        if let index = todaySummary.switchEdges.firstIndex(where: {
            $0.fromBundleId == from && $0.toBundleId == to
        }) {
            todaySummary.switchEdges[index].count += 1
        } else {
            todaySummary.switchEdges.append(SwitchEdge(from: from, to: to))
        }
        saveTodayData()
    }
    
    // MARK: - Bookmarks
    
    /// 添加书签
    func addBookmark(_ bookmark: Bookmark) {
        checkDayChange()
        todaySummary.bookmarks.append(bookmark)
        saveTodayData()
    }
    
    /// 删除书签
    func removeBookmark(id: UUID) {
        todaySummary.bookmarks.removeAll { $0.id == id }
        saveTodayData()
    }
    
    // MARK: - Focus Sessions
    
    /// 添加专注会话
    func addFocusSession(_ session: FocusSession) {
        checkDayChange()
        todaySummary.focusSessions.append(session)
        saveTodayData()
    }
    
    // MARK: - Filtering
    
    /// 检查是否应该过滤该应用
    private func shouldFilter(bundleId: String) -> Bool {
        if settings.whitelistMode {
            return !settings.whitelistedBundleIds.contains(bundleId)
        }
        return settings.blacklistedBundleIds.contains(bundleId)
    }
    
    // MARK: - Day Change
    
    /// 检查是否跨天，如果是则保存旧数据并创建新的今日数据
    private func checkDayChange() {
        let today = dateString()
        if todaySummary.date != today {
            saveTodayData()
            todaySummary = DailySummary(date: today)
        }
    }
    
    // MARK: - Data Retention
    
    /// 清理过期数据
    private func cleanupOldData() {
        let retentionDays = settings.dataRetentionDays
        let calendar = Calendar.current
        
        guard let cutoffDate = calendar.date(byAdding: .day, value: -retentionDays, to: Date()) else {
            return
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: dataDirectory, includingPropertiesForKeys: nil)
            
            for file in files where file.lastPathComponent.hasPrefix("segments_") {
                // 从文件名提取日期
                let filename = file.deletingPathExtension().lastPathComponent
                let dateStr = String(filename.dropFirst("segments_".count))
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                // 删除过期文件
                if let fileDate = formatter.date(from: dateStr), fileDate < cutoffDate {
                    try fileManager.removeItem(at: file)
                    print("Cleaned up old data: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("Failed to cleanup old data: \(error)")
        }
    }
    
    // MARK: - Export
    
    /// 导出为 CSV 格式
    func exportToCSV() -> URL? {
        var csv = "ID,Start Time,End Time,Duration (s),Bundle ID,App Name,Window Title,Label,Project,Is Meeting,Engagement\n"
        
        for segment in todaySummary.segments {
            let row = "\(segment.id),\(segment.startTime),\(segment.endTime),\(Int(segment.durationSeconds)),\(segment.bundleId),\"\(segment.appName)\",\"\(segment.windowTitle ?? "")\",\"\(segment.labelId ?? "")\",\"\(segment.projectId ?? "")\",\(segment.isMeeting),\(segment.engagementScore ?? 0)\n"
            csv += row
        }
        
        let exportPath = dataDirectory.appendingPathComponent("export_\(todaySummary.date).csv")
        
        do {
            try csv.write(to: exportPath, atomically: true, encoding: .utf8)
            return exportPath
        } catch {
            print("Failed to export CSV: \(error)")
            return nil
        }
    }
    
    /// 导出为 JSON 格式
    func exportToJSON() -> URL? {
        let exportPath = dataDirectory.appendingPathComponent("export_\(todaySummary.date).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(todaySummary)
            try data.write(to: exportPath)
            return exportPath
        } catch {
            print("Failed to export JSON: \(error)")
            return nil
        }
    }
    
    /// 导出时间账单
    /// - Parameter groupBy: 分组方式（label/project/app）
    func exportTimesheet(groupBy: String = "label") -> URL? {
        var timesheet: [String: TimeInterval] = [:]
        
        for segment in todaySummary.segments where !segment.isIdle {
            let key: String
            switch groupBy {
            case "project":
                key = segment.projectId ?? "未分类"
            case "app":
                key = segment.appName
            default:
                key = segment.labelId ?? "未分类"
            }
            timesheet[key, default: 0] += segment.durationSeconds
        }
        
        var csv = "类别,时长(分钟),时长(小时)\n"
        for (key, duration) in timesheet.sorted(by: { $0.value > $1.value }) {
            csv += "\"\(key)\",\(Int(duration/60)),\(String(format: "%.2f", duration/3600))\n"
        }
        
        let exportPath = dataDirectory.appendingPathComponent("timesheet_\(todaySummary.date).csv")
        
        do {
            try csv.write(to: exportPath, atomically: true, encoding: .utf8)
            return exportPath
        } catch {
            print("Failed to export timesheet: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear Data
    
    /// 清空今日数据
    func clearTodayData() {
        let today = dateString()
        todaySummary = DailySummary(date: today)
        saveTodayData()
    }
}
