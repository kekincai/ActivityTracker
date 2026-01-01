//
//  BookmarkManager.swift
//  ActivityTracker
//
//  书签管理器
//  管理用户手动添加的事件标记
//

import Foundation

/// 书签管理器
/// 允许用户在时间轴上添加手动标记
class BookmarkManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = BookmarkManager()
    
    // MARK: - Published Properties
    
    /// 今日书签列表
    @Published var todayBookmarks: [Bookmark] = []
    
    // MARK: - Initialization
    
    private init() {
        loadTodayBookmarks()
    }
    
    // MARK: - Public Methods
    
    /// 添加书签
    /// - Parameters:
    ///   - text: 书签文本
    ///   - colorTag: 颜色标签（可选）
    func addBookmark(text: String, colorTag: String? = nil) {
        let bookmark = Bookmark(text: text, colorTag: colorTag)
        DataStore.shared.addBookmark(bookmark)
        loadTodayBookmarks()
    }
    
    /// 删除书签
    /// - Parameter id: 书签 ID
    func removeBookmark(id: UUID) {
        DataStore.shared.removeBookmark(id: id)
        loadTodayBookmarks()
    }
    
    /// 加载今日书签
    func loadTodayBookmarks() {
        todayBookmarks = DataStore.shared.todaySummary.bookmarks
    }
    
    // MARK: - Presets
    
    /// 预设书签模板
    static let presets: [(text: String, color: String)] = [
        ("开始工作", "blue"),
        ("休息", "green"),
        ("会议开始", "orange"),
        ("写周报", "purple"),
        ("学习", "cyan")
    ]
}
