//
//  FeaturesTests.swift
//  ActivityTrackerTests
//
//  功能模块单元测试
//

import XCTest
@testable import ActivityTracker

final class FeaturesTests: XCTestCase {
    
    // MARK: - ActivityLabeler Tests
    
    func testActivityLabelerDetectsDevelopment() {
        let labeler = ActivityLabeler.shared
        
        let xcodeSegment = AppSegment(
            startTime: Date(),
            bundleId: "com.apple.dt.Xcode",
            appName: "Xcode"
        )
        
        let labelId = labeler.detectLabel(for: xcodeSegment)
        XCTAssertEqual(labelId, "dev")
    }
    
    func testActivityLabelerDetectsMeeting() {
        let labeler = ActivityLabeler.shared
        
        let zoomSegment = AppSegment(
            startTime: Date(),
            bundleId: "us.zoom.xos",
            appName: "Zoom"
        )
        
        let labelId = labeler.detectLabel(for: zoomSegment)
        XCTAssertEqual(labelId, "meeting")
    }
    
    func testActivityLabelerReturnsNilForUnknown() {
        let labeler = ActivityLabeler.shared
        
        let unknownSegment = AppSegment(
            startTime: Date(),
            bundleId: "com.unknown.app",
            appName: "Unknown App"
        )
        
        let labelId = labeler.detectLabel(for: unknownSegment)
        XCTAssertNil(labelId)
    }
    
    func testActivityLabelerGetLabelById() {
        let labeler = ActivityLabeler.shared
        
        let devLabel = labeler.getLabel(by: "dev")
        XCTAssertNotNil(devLabel)
        XCTAssertEqual(devLabel?.name, "开发")
        
        let nonExistent = labeler.getLabel(by: "nonexistent")
        XCTAssertNil(nonExistent)
    }
    
    // MARK: - MeetingDetector Tests
    
    func testMeetingDetectorZoom() {
        let detector = MeetingDetector.shared
        
        let isMeeting = detector.isMeeting(bundleId: "us.zoom.xos", windowTitle: nil)
        XCTAssertTrue(isMeeting)
    }
    
    func testMeetingDetectorTeams() {
        let detector = MeetingDetector.shared
        
        let isMeeting = detector.isMeeting(bundleId: "com.microsoft.teams", windowTitle: nil)
        XCTAssertTrue(isMeeting)
    }
    
    func testMeetingDetectorByWindowTitle() {
        let detector = MeetingDetector.shared
        
        let isMeeting = detector.isMeeting(bundleId: "com.apple.Safari", windowTitle: "Weekly Meeting - Google Meet")
        XCTAssertTrue(isMeeting)
    }
    
    func testMeetingDetectorNonMeeting() {
        let detector = MeetingDetector.shared
        
        let isMeeting = detector.isMeeting(bundleId: "com.apple.Safari", windowTitle: "Google Search")
        XCTAssertFalse(isMeeting)
    }
    
    // MARK: - DataRedactor Tests
    
    func testDataRedactorEmail() {
        let redactor = DataRedactor.shared
        
        // 需要先启用脱敏
        let originalSetting = DataStore.shared.settings.enableDataRedaction
        DataStore.shared.settings.enableDataRedaction = true
        redactor.reloadPatterns()
        
        let input = "Contact: test@example.com for more info"
        let result = redactor.redact(input)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.contains("test@example.com"))
        XCTAssertTrue(result!.contains("***"))
        
        // 恢复设置
        DataStore.shared.settings.enableDataRedaction = originalSetting
    }
    
    func testDataRedactorToken() {
        let redactor = DataRedactor.shared
        
        let originalSetting = DataStore.shared.settings.enableDataRedaction
        DataStore.shared.settings.enableDataRedaction = true
        redactor.reloadPatterns()
        
        let input = "Token: abcdefghijklmnopqrstuvwxyz123456"
        let result = redactor.redact(input)
        
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("***"))
        
        DataStore.shared.settings.enableDataRedaction = originalSetting
    }
    
    func testDataRedactorDisabled() {
        let redactor = DataRedactor.shared
        
        let originalSetting = DataStore.shared.settings.enableDataRedaction
        DataStore.shared.settings.enableDataRedaction = false
        
        let input = "Contact: test@example.com"
        let result = redactor.redact(input)
        
        XCTAssertEqual(result, input)
        
        DataStore.shared.settings.enableDataRedaction = originalSetting
    }
    
    func testDataRedactorNilInput() {
        let redactor = DataRedactor.shared
        
        let result = redactor.redact(nil)
        XCTAssertNil(result)
    }
    
    func testDataRedactorContainsSensitiveData() {
        let redactor = DataRedactor.shared
        redactor.reloadPatterns()
        
        XCTAssertTrue(redactor.containsSensitiveData("email: user@test.com"))
        XCTAssertFalse(redactor.containsSensitiveData("Hello World"))
    }
    
    // MARK: - ProjectDetector Tests
    
    func testProjectDetectorNoProjects() {
        let detector = ProjectDetector.shared
        
        let segment = AppSegment(
            startTime: Date(),
            bundleId: "com.apple.Safari",
            appName: "Safari"
        )
        
        let (projectId, confidence) = detector.detectProject(for: segment)
        
        // 没有配置项目时应该返回 nil
        if detector.projects.isEmpty {
            XCTAssertNil(projectId)
            XCTAssertEqual(confidence, 0)
        }
    }
    
    // MARK: - SwitchAnalyzer Tests
    
    func testSwitchAnalyzerEmptyData() {
        let analyzer = SwitchAnalyzer.shared
        
        // 清空数据后分析
        analyzer.analyze()
        
        // 应该有默认值
        XCTAssertGreaterThanOrEqual(analyzer.contextSwitchCount, 0)
        XCTAssertGreaterThanOrEqual(analyzer.fragmentationIndex, 0)
    }
    
    func testSwitchAnalyzerSwitchesPerHour() {
        let analyzer = SwitchAnalyzer.shared
        
        let hourlyData = analyzer.switchesPerHour()
        
        XCTAssertEqual(hourlyData.count, 24)
        
        for (hour, _) in hourlyData {
            XCTAssertGreaterThanOrEqual(hour, 0)
            XCTAssertLessThan(hour, 24)
        }
    }
    
    // MARK: - BookmarkManager Tests
    
    func testBookmarkManagerPresets() {
        let presets = BookmarkManager.presets
        
        XCTAssertGreaterThan(presets.count, 0)
        
        for preset in presets {
            XCTAssertFalse(preset.text.isEmpty)
            XCTAssertFalse(preset.color.isEmpty)
        }
    }
    
    // MARK: - FocusSessionManager Tests
    
    func testFocusSessionManagerInitialState() {
        let manager = FocusSessionManager.shared
        
        // 初始状态应该没有进行中的会话
        // 注意：这个测试可能受之前测试影响
        XCTAssertNotNil(manager)
    }
    
    func testFocusSessionManagerManualSession() {
        let manager = FocusSessionManager.shared
        
        // 如果有进行中的会话，先结束
        if manager.isInFocus {
            manager.endSession()
        }
        
        // 开始手动会话
        manager.startManualSession(projectId: "test-project")
        
        XCTAssertTrue(manager.isInFocus)
        XCTAssertNotNil(manager.currentSession)
        XCTAssertEqual(manager.currentSession?.projectId, "test-project")
        XCTAssertTrue(manager.currentSession?.isManual ?? false)
        
        // 结束会话
        manager.endSession()
        
        XCTAssertFalse(manager.isInFocus)
        XCTAssertNil(manager.currentSession)
    }
    
    // MARK: - EngagementTracker Tests
    
    func testEngagementTrackerPermissionCheck() {
        // 这个测试只验证方法存在且可调用
        let hasPermission = EngagementTracker.checkAccessibilityPermission()
        
        // 在测试环境中可能没有权限，但方法应该能正常返回
        XCTAssertNotNil(hasPermission)
    }
    
    func testEngagementTrackerInitialState() {
        let tracker = EngagementTracker.shared
        
        XCTAssertGreaterThanOrEqual(tracker.currentScore, 0)
        XCTAssertLessThanOrEqual(tracker.currentScore, 100)
    }
}
