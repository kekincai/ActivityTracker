//
//  ProjectDetector.swift
//  ActivityTracker
//
//  项目检测器
//  自动将应用使用归类到特定项目
//

import Foundation

/// 项目检测器
/// 根据窗口标题、Bundle ID、文件路径等规则自动识别项目
class ProjectDetector: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = ProjectDetector()
    
    // MARK: - Published Properties
    
    /// 项目列表
    @Published var projects: [Project] = []
    
    // MARK: - Initialization
    
    private init() {
        loadProjects()
    }
    
    // MARK: - Project Detection
    
    /// 检测分段所属的项目
    /// - Parameter segment: 应用使用分段
    /// - Returns: (项目ID, 置信度) 元组
    func detectProject(for segment: AppSegment) -> (projectId: String?, confidence: Double) {
        guard DataStore.shared.settings.enableProjectDetection else {
            return (nil, 0)
        }
        
        var bestMatch: (projectId: String?, confidence: Double) = (nil, 0)
        
        // 遍历所有项目，找出最佳匹配
        for project in projects {
            let confidence = matchConfidence(segment: segment, project: project)
            if confidence > bestMatch.confidence {
                bestMatch = (project.id, confidence)
            }
        }
        
        // 置信度需要达到 0.5 以上才返回
        return bestMatch.confidence >= 0.5 ? bestMatch : (nil, 0)
    }
    
    /// 计算分段与项目的匹配置信度
    private func matchConfidence(segment: AppSegment, project: Project) -> Double {
        var totalScore: Double = 0
        var matchCount = 0
        
        for rule in project.rules {
            let score = matchRule(segment: segment, rule: rule)
            if score > 0 {
                totalScore += score
                matchCount += 1
            }
        }
        
        guard matchCount > 0 else { return 0 }
        return min(totalScore / Double(matchCount), 1.0)
    }
    
    /// 计算单条规则的匹配分数
    private func matchRule(segment: AppSegment, rule: ProjectRule) -> Double {
        switch rule.type {
        case .windowTitleRegex:
            // 窗口标题正则匹配
            guard let title = segment.windowTitle,
                  let regex = try? NSRegularExpression(pattern: rule.pattern, options: .caseInsensitive) else {
                return 0
            }
            let range = NSRange(title.startIndex..., in: title)
            return regex.firstMatch(in: title, range: range) != nil ? 0.8 : 0
            
        case .bundleIdKeyword:
            // Bundle ID 关键字匹配
            let bundleId = segment.bundleId.lowercased()
            let keyword = rule.pattern.lowercased()
            return bundleId.contains(keyword) ? 0.7 : 0
            
        case .filePathPrefix:
            // 文件路径前缀匹配
            guard let title = segment.windowTitle else { return 0 }
            return title.contains(rule.pattern) ? 0.9 : 0
        }
    }
    
    // MARK: - Project Management
    
    /// 添加项目
    func addProject(_ project: Project) {
        projects.append(project)
        saveProjects()
    }
    
    /// 删除项目
    func removeProject(id: String) {
        projects.removeAll { $0.id == id }
        saveProjects()
    }
    
    /// 更新项目
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
        }
    }
    
    // MARK: - Persistence
    
    /// 项目文件路径
    private var projectsFilePath: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("ActivityTracker/projects.json")
    }
    
    /// 加载项目
    private func loadProjects() {
        guard FileManager.default.fileExists(atPath: projectsFilePath.path) else { return }
        
        do {
            let data = try Data(contentsOf: projectsFilePath)
            projects = try JSONDecoder().decode([Project].self, from: data)
        } catch {
            print("Failed to load projects: \(error)")
        }
    }
    
    /// 保存项目
    private func saveProjects() {
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: projectsFilePath)
        } catch {
            print("Failed to save projects: \(error)")
        }
    }
}
