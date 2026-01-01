//
//  ActivityLabeler.swift
//  ActivityTracker
//
//  活动标签分类器
//  自动将应用使用分类为不同的活动类型（开发/写作/学习/娱乐等）
//

import Foundation

/// 活动标签分类器
/// 根据 Bundle ID 和窗口标题自动识别活动类型
class ActivityLabeler: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = ActivityLabeler()
    
    // MARK: - Published Properties
    
    /// 标签列表
    @Published var labels: [ActivityLabel] = ActivityLabel.defaults
    
    // MARK: - Initialization
    
    private init() {
        loadLabels()
    }
    
    // MARK: - Label Detection
    
    /// 检测分段的活动标签
    /// - Parameter segment: 应用使用分段
    /// - Returns: 匹配的标签 ID，未匹配返回 nil
    func detectLabel(for segment: AppSegment) -> String? {
        guard DataStore.shared.settings.enableActivityLabels else { return nil }
        
        // 优先匹配 Bundle ID
        for label in labels {
            for bundleId in label.bundleIds {
                if segment.bundleId.lowercased().contains(bundleId.lowercased()) {
                    return label.id
                }
            }
        }
        
        // 其次匹配窗口标题关键字
        if let title = segment.windowTitle?.lowercased() {
            for label in labels {
                for keyword in label.titleKeywords {
                    if title.contains(keyword.lowercased()) {
                        return label.id
                    }
                }
            }
        }
        
        return nil
    }
    
    /// 根据 ID 获取标签
    func getLabel(by id: String) -> ActivityLabel? {
        labels.first { $0.id == id }
    }
    
    // MARK: - Label Management
    
    /// 添加标签
    func addLabel(_ label: ActivityLabel) {
        labels.append(label)
        saveLabels()
    }
    
    /// 更新标签
    func updateLabel(_ label: ActivityLabel) {
        if let index = labels.firstIndex(where: { $0.id == label.id }) {
            labels[index] = label
            saveLabels()
        }
    }
    
    /// 删除标签
    func removeLabel(id: String) {
        labels.removeAll { $0.id == id }
        saveLabels()
    }
    
    // MARK: - Persistence
    
    /// 标签文件路径
    private var labelsFilePath: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("ActivityTracker/labels.json")
    }
    
    /// 加载标签
    private func loadLabels() {
        guard FileManager.default.fileExists(atPath: labelsFilePath.path) else { return }
        
        do {
            let data = try Data(contentsOf: labelsFilePath)
            labels = try JSONDecoder().decode([ActivityLabel].self, from: data)
        } catch {
            print("Failed to load labels: \(error)")
        }
    }
    
    /// 保存标签
    private func saveLabels() {
        do {
            let data = try JSONEncoder().encode(labels)
            try data.write(to: labelsFilePath)
        } catch {
            print("Failed to save labels: \(error)")
        }
    }
}
