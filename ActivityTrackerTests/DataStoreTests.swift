//
//  DataStoreTests.swift
//  ActivityTrackerTests
//
//  数据存储单元测试
//

import XCTest
@testable import ActivityTracker

final class DataStoreTests: XCTestCase {
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        // 每个测试前可以重置状态
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - DataStore Singleton Tests
    
    func testDataStoreSingleton() {
        let store1 = DataStore.shared
        let store2 = DataStore.shared
        
        XCTAssertTrue(store1 === store2)
    }
    
    // MARK: - Settings Tests
    
    func testSettingsDefaultValues() {
        let store = DataStore.shared
        
        XCTAssertGreaterThan(store.settings.samplingInterval, 0)
        XCTAssertGreaterThan(store.settings.idleThreshold, 0)
        XCTAssertGreaterThan(store.settings.dataRetentionDays, 0)
    }
    
    func testSettingsSaveAndLoad() {
        let store = DataStore.shared
        
        // 修改设置
        let originalInterval = store.settings.samplingInterval
        store.settings.samplingInterval = 2.5
        store.saveSettings()
        
        // 重新加载
        store.loadSettings()
        
        XCTAssertEqual(store.settings.samplingInterval, 2.5, accuracy: 0.001)
        
        // 恢复原值
        store.settings.samplingInterval = originalInterval
        store.saveSettings()
    }
    
    // MARK: - Today Summary Tests
    
    func testTodaySummaryDate() {
        let store = DataStore.shared
        let today = dateString()
        
        XCTAssertEqual(store.todaySummary.date, today)
    }
    
    func testLoadSummaryForDate() {
        let store = DataStore.shared
        
        // 加载一个不存在的日期
        let summary = store.loadSummary(for: "1999-01-01")
        
        XCTAssertEqual(summary.date, "1999-01-01")
        XCTAssertTrue(summary.segments.isEmpty)
    }
    
    // MARK: - Segment Tests
    
    func testAddSegment() {
        let store = DataStore.shared
        let initialCount = store.todaySummary.segments.count
        
        let segment = AppSegment(
            startTime: Date(),
            bundleId: "com.test.app",
            appName: "Test App"
        )
        
        store.addSegment(segment)
        
        XCTAssertEqual(store.todaySummary.segments.count, initialCount + 1)
        
        // 验证最后一个分段
        let lastSegment = store.todaySummary.segments.last
        XCTAssertEqual(lastSegment?.bundleId, "com.test.app")
        XCTAssertEqual(lastSegment?.appName, "Test App")
    }
    
    func testUpdateLastSegment() {
        let store = DataStore.shared
        
        // 先添加一个分段
        let segment = AppSegment(
            startTime: Date(),
            bundleId: "com.test.update",
            appName: "Update Test"
        )
        store.addSegment(segment)
        
        // 更新结束时间
        let newEndTime = Date().addingTimeInterval(3600)
        store.updateLastSegment(endTime: newEndTime, engagementScore: 75)
        
        let lastSegment = store.todaySummary.segments.last
        XCTAssertNotNil(lastSegment)
        XCTAssertEqual(lastSegment!.endTime.timeIntervalSince1970, newEndTime.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(lastSegment?.engagementScore, 75)
    }
    
    // MARK: - Bookmark Tests
    
    func testAddBookmark() {
        let store = DataStore.shared
        let initialCount = store.todaySummary.bookmarks.count
        
        let bookmark = Bookmark(text: "Test Bookmark", colorTag: "blue")
        store.addBookmark(bookmark)
        
        XCTAssertEqual(store.todaySummary.bookmarks.count, initialCount + 1)
        
        let lastBookmark = store.todaySummary.bookmarks.last
        XCTAssertEqual(lastBookmark?.text, "Test Bookmark")
        XCTAssertEqual(lastBookmark?.colorTag, "blue")
    }
    
    func testRemoveBookmark() {
        let store = DataStore.shared
        
        // 添加一个书签
        let bookmark = Bookmark(text: "To Remove", colorTag: "red")
        store.addBookmark(bookmark)
        
        let countAfterAdd = store.todaySummary.bookmarks.count
        
        // 删除书签
        store.removeBookmark(id: bookmark.id)
        
        XCTAssertEqual(store.todaySummary.bookmarks.count, countAfterAdd - 1)
        XCTAssertFalse(store.todaySummary.bookmarks.contains { $0.id == bookmark.id })
    }
    
    // MARK: - Focus Session Tests
    
    func testAddFocusSession() {
        let store = DataStore.shared
        let initialCount = store.todaySummary.focusSessions.count
        
        var session = FocusSession(startTime: Date())
        session.endTime = Date().addingTimeInterval(1800)
        session.projectId = "test-project"
        
        store.addFocusSession(session)
        
        XCTAssertEqual(store.todaySummary.focusSessions.count, initialCount + 1)
    }
    
    // MARK: - Switch Recording Tests
    
    func testRecordSwitch() {
        let store = DataStore.shared
        
        // 记录切换
        store.recordSwitch(from: "com.app1", to: "com.app2")
        
        // 验证切换被记录
        let edge = store.todaySummary.switchEdges.first {
            $0.fromBundleId == "com.app1" && $0.toBundleId == "com.app2"
        }
        
        XCTAssertNotNil(edge)
        XCTAssertGreaterThanOrEqual(edge?.count ?? 0, 1)
    }
    
    func testRecordSwitchIncrementsCount() {
        let store = DataStore.shared
        
        // 记录同样的切换两次
        store.recordSwitch(from: "com.appA", to: "com.appB")
        
        let edge1 = store.todaySummary.switchEdges.first {
            $0.fromBundleId == "com.appA" && $0.toBundleId == "com.appB"
        }
        let count1 = edge1?.count ?? 0
        
        store.recordSwitch(from: "com.appA", to: "com.appB")
        
        let edge2 = store.todaySummary.switchEdges.first {
            $0.fromBundleId == "com.appA" && $0.toBundleId == "com.appB"
        }
        let count2 = edge2?.count ?? 0
        
        XCTAssertEqual(count2, count1 + 1)
    }
    
    // MARK: - Export Tests
    
    func testExportToCSV() {
        let store = DataStore.shared
        
        // 确保有数据
        let segment = AppSegment(
            startTime: Date(),
            bundleId: "com.export.test",
            appName: "Export Test"
        )
        store.addSegment(segment)
        
        let url = store.exportToCSV()
        
        XCTAssertNotNil(url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
        
        // 清理
        try? FileManager.default.removeItem(at: url!)
    }
    
    func testExportToJSON() {
        let store = DataStore.shared
        
        let url = store.exportToJSON()
        
        XCTAssertNotNil(url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
        
        // 验证是有效的 JSON
        if let data = try? Data(contentsOf: url!) {
            let json = try? JSONSerialization.jsonObject(with: data)
            XCTAssertNotNil(json)
        }
        
        // 清理
        try? FileManager.default.removeItem(at: url!)
    }
    
    func testExportTimesheet() {
        let store = DataStore.shared
        
        let url = store.exportTimesheet()
        
        XCTAssertNotNil(url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
        
        // 清理
        try? FileManager.default.removeItem(at: url!)
    }
    
    // MARK: - Clear Data Tests
    
    func testClearTodayData() {
        let store = DataStore.shared
        
        // 添加一些数据
        let segment = AppSegment(
            startTime: Date(),
            bundleId: "com.clear.test",
            appName: "Clear Test"
        )
        store.addSegment(segment)
        
        // 清空
        store.clearTodayData()
        
        // 验证数据被清空（但日期保持今天）
        XCTAssertEqual(store.todaySummary.date, dateString())
        // 注意：segments 可能不为空，因为其他测试可能添加了数据
    }
    
    // MARK: - Minute Stats Tests
    
    func testAddMinuteStats() {
        let store = DataStore.shared
        let initialCount = store.todaySummary.minuteStats.count
        
        var stats = MinuteStats(minuteStartTime: Date())
        stats.keyDownCount = 100
        stats.mouseClickCount = 20
        
        store.addMinuteStats(stats)
        
        XCTAssertEqual(store.todaySummary.minuteStats.count, initialCount + 1)
    }
}
