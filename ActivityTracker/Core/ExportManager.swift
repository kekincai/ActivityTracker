//
//  ExportManager.swift
//  ActivityTracker
//
//  导出管理器
//  负责数据导出功能
//

import Foundation
import AppKit

/// 导出管理器
/// 提供 CSV、JSON、时间账单等导出功能
class ExportManager {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = ExportManager()
    
    // MARK: - Private Properties
    
    private let dataStore = DataStore.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 导出 CSV 文件
    func exportCSV() {
        guard let url = dataStore.exportToCSV() else {
            showAlert(title: "导出失败", message: "无法导出 CSV 文件")
            return
        }
        revealInFinder(url)
    }
    
    /// 导出 JSON 文件
    func exportJSON() {
        guard let url = dataStore.exportToJSON() else {
            showAlert(title: "导出失败", message: "无法导出 JSON 文件")
            return
        }
        revealInFinder(url)
    }
    
    /// 导出时间账单
    func exportTimesheet() {
        guard let url = dataStore.exportTimesheet() else {
            showAlert(title: "导出失败", message: "无法导出时间账单")
            return
        }
        revealInFinder(url)
    }
    
    // MARK: - Private Methods
    
    /// 在 Finder 中显示文件
    private func revealInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(
            url.path,
            inFileViewerRootedAtPath: url.deletingLastPathComponent().path
        )
    }
    
    /// 显示警告对话框
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}
