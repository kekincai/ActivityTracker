//
//  ModelsTests.swift
//  ActivityTrackerTests
//
//  数据模型单元测试
//

import XCTest
@testable import ActivityTracker

final class ModelsTests: XCTestCase {
    
    // MARK: - AppSegment Tests
    
    func testAppSegmentCreation() {
        let startTime = Date()
        let segment = AppSegment(
            startTime: startTime,
            bundleId: "com.apple.Safari",
            appName: "Safari"
        )
        
        XCTAssertEqual(segment.bundleId, "com.apple.Safari")
        XCTAssertEqual(segment.appName, "Safari")
        XCTAssertEqual(segment.startTime, startTime)
        XCTAssertFalse(segment.isIdle)
        XCTAssertNil(segment.windowTitle)
        XCTAssertNil(segment.labelId)
        XCTAssertNil(segment.projectId)
    }
    
    func testAppSegmentDuration() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600) // 1 hour
        
        var segment = AppSegment(
            startTime: startTime,
            bundleId: "com.apple.Safari",
            appName: "Safari"
        )
        segment.endTime = endTime
        
        XCTAssertEqual(segment.durationSeconds, 3600, accuracy: 0.001)
    }
    
    func testAppSegmentIdleState() {
        let segment = AppSegment(
            startTime: Date(),
            bundleId: AppSegment.idle,
            appName: AppSegment.idleName
        )
        
        XCTAssertTrue(segment.isIdle)
        XCTAssertEqual(segment.bundleId, "idle")
        XCTAssertEqual(segment.appName, "Idle")
    }
    
    func testAppSegmentEquality() {
        let id = UUID()
        let time = Date()
        
        let segment1 = AppSegment(
            id: id,
            startTime: time,
            bundleId: "com.test",
            appName: "Test"
        )
        let segment2 = AppSegment(
            id: id,
            startTime: time,
            bundleId: "com.test",
            appName: "Test"
        )
        
        // AppSegment 使用 id 进行相等性比较
        XCTAssertEqual(segment1.id, segment2.id)
        XCTAssertEqual(segment1.bundleId, segment2.bundleId)
        XCTAssertEqual(segment1.appName, segment2.appName)
    }
    
    // MARK: - DailySummary Tests
    
    func testDailySummaryCreation() {
        let summary = DailySummary(date: "2024-01-15")
        
        XCTAssertEqual(summary.date, "2024-01-15")
        XCTAssertTrue(summary.segments.isEmpty)
        XCTAssertEqual(summary.totalActiveTime, 0)
        XCTAssertEqual(summary.totalIdleTime, 0)
    }
    
    func testDailySummaryRecalculate() {
        var summary = DailySummary(date: "2024-01-15")
        
        // 添加活跃分段
        var activeSegment = AppSegment(
            startTime: Date(),
            bundleId: "com.apple.Safari",
            appName: "Safari"
        )
        activeSegment.endTime = activeSegment.startTime.addingTimeInterval(1800) // 30 min
        
        // 添加空闲分段
        var idleSegment = AppSegment(
            startTime: Date(),
            bundleId: AppSegment.idle,
            appName: AppSegment.idleName
        )
        idleSegment.endTime = idleSegment.startTime.addingTimeInterval(600) // 10 min
        
        summary.segments = [activeSegment, idleSegment]
        summary.recalculate()
        
        XCTAssertEqual(summary.totalActiveTime, 1800, accuracy: 0.001)
        XCTAssertEqual(summary.totalIdleTime, 600, accuracy: 0.001)
    }
    
    func testDailySummaryContextSwitchCount() {
        var summary = DailySummary(date: "2024-01-15")
        
        let segment1 = AppSegment(startTime: Date(), bundleId: "com.app1", appName: "App1")
        let segment2 = AppSegment(startTime: Date(), bundleId: "com.app2", appName: "App2")
        let segment3 = AppSegment(startTime: Date(), bundleId: "com.app1", appName: "App1")
        let segment4 = AppSegment(startTime: Date(), bundleId: "com.app3", appName: "App3")
        
        summary.segments = [segment1, segment2, segment3, segment4]
        
        XCTAssertEqual(summary.contextSwitchCount, 3)
    }
    
    // MARK: - Bookmark Tests
    
    func testBookmarkCreation() {
        let bookmark = Bookmark(text: "开始工作", colorTag: "blue")
        
        XCTAssertEqual(bookmark.text, "开始工作")
        XCTAssertEqual(bookmark.colorTag, "blue")
        XCTAssertNotNil(bookmark.id)
    }
    
    // MARK: - FocusSession Tests
    
    func testFocusSessionDuration() {
        var session = FocusSession(startTime: Date())
        session.endTime = session.startTime.addingTimeInterval(3600)
        
        XCTAssertEqual(session.durationSeconds, 3600, accuracy: 0.001)
        XCTAssertTrue(session.isManual)
    }
    
    func testFocusSessionOngoing() {
        let session = FocusSession(startTime: Date().addingTimeInterval(-1800))
        
        // 未结束的会话，duration 应该是从开始到现在
        XCTAssertGreaterThan(session.durationSeconds, 1799)
        XCTAssertNil(session.endTime)
    }
    
    // MARK: - MinuteStats Tests
    
    func testMinuteStatsTotalActivity() {
        var stats = MinuteStats(minuteStartTime: Date())
        stats.keyDownCount = 50
        stats.mouseClickCount = 10
        stats.scrollCount = 5
        
        XCTAssertEqual(stats.totalActivity, 65)
    }
    
    // MARK: - Goal Tests
    
    func testGoalCreation() {
        let goal = Goal(
            name: "编码目标",
            targetMinutes: 180,
            isUpperLimit: false,
            filterType: .label,
            filterValue: "dev"
        )
        
        XCTAssertEqual(goal.name, "编码目标")
        XCTAssertEqual(goal.targetMinutes, 180)
        XCTAssertFalse(goal.isUpperLimit)
        XCTAssertEqual(goal.filterType, .label)
        XCTAssertEqual(goal.filterValue, "dev")
        XCTAssertTrue(goal.isEnabled)
    }
    
    // MARK: - TrackerSettings Tests
    
    func testDefaultSettings() {
        let settings = TrackerSettings.default
        
        XCTAssertEqual(settings.samplingInterval, 1.0)
        XCTAssertEqual(settings.idleThreshold, 300.0)
        XCTAssertEqual(settings.dataRetentionDays, 90)
        XCTAssertFalse(settings.enableWindowTitle)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertTrue(settings.enableProjectDetection)
        XCTAssertTrue(settings.enableActivityLabels)
        XCTAssertTrue(settings.enableMeetingDetection)
    }
    
    // MARK: - EngagementMode Tests
    
    func testEngagementModeFromScore() {
        XCTAssertEqual(EngagementMode.from(score: 80), .focus)
        XCTAssertEqual(EngagementMode.from(score: 70), .focus)
        XCTAssertEqual(EngagementMode.from(score: 50), .light)
        XCTAssertEqual(EngagementMode.from(score: 30), .light)
        XCTAssertEqual(EngagementMode.from(score: 20), .passive)
        XCTAssertEqual(EngagementMode.from(score: 0), .passive)
    }
    
    // MARK: - ActivityLabel Tests
    
    func testDefaultActivityLabels() {
        let labels = ActivityLabel.defaults
        
        XCTAssertGreaterThan(labels.count, 0)
        XCTAssertTrue(labels.contains { $0.id == "dev" })
        XCTAssertTrue(labels.contains { $0.id == "meeting" })
        XCTAssertTrue(labels.contains { $0.id == "entertainment" })
    }
    
    // MARK: - Project Tests
    
    func testProjectCreation() {
        let rule = ProjectRule(type: .windowTitleRegex, pattern: "\\[MyProject\\]")
        let project = Project(name: "My Project", rules: [rule], color: "blue")
        
        XCTAssertEqual(project.name, "My Project")
        XCTAssertEqual(project.rules.count, 1)
        XCTAssertEqual(project.color, "blue")
    }
    
    // MARK: - SwitchEdge Tests
    
    func testSwitchEdgeCreation() {
        var edge = SwitchEdge(from: "com.app1", to: "com.app2")
        edge.count = 5
        edge.totalDuration = 300
        
        XCTAssertEqual(edge.fromBundleId, "com.app1")
        XCTAssertEqual(edge.toBundleId, "com.app2")
        XCTAssertEqual(edge.count, 5)
        XCTAssertEqual(edge.totalDuration, 300)
    }
}
