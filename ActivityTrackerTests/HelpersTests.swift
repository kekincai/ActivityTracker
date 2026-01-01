//
//  HelpersTests.swift
//  ActivityTrackerTests
//
//  工具函数单元测试
//

import XCTest
@testable import ActivityTracker

final class HelpersTests: XCTestCase {
    
    // MARK: - formatDuration Tests
    
    func testFormatDurationSeconds() {
        XCTAssertEqual(formatDuration(0), "0s")
        XCTAssertEqual(formatDuration(30), "30s")
        XCTAssertEqual(formatDuration(59), "59s")
    }
    
    func testFormatDurationMinutes() {
        XCTAssertEqual(formatDuration(60), "1m 0s")
        XCTAssertEqual(formatDuration(90), "1m 30s")
        XCTAssertEqual(formatDuration(3599), "59m 59s")
    }
    
    func testFormatDurationHours() {
        XCTAssertEqual(formatDuration(3600), "1h 0m")
        XCTAssertEqual(formatDuration(5400), "1h 30m")
        XCTAssertEqual(formatDuration(7200), "2h 0m")
        XCTAssertEqual(formatDuration(9000), "2h 30m")
    }
    
    func testFormatDurationLarge() {
        XCTAssertEqual(formatDuration(36000), "10h 0m")
        XCTAssertEqual(formatDuration(86400), "24h 0m")
    }
    
    // MARK: - dateString Tests
    
    func testDateStringFormat() {
        let dateString = dateString()
        
        // 验证格式 yyyy-MM-dd
        let regex = try! NSRegularExpression(pattern: "^\\d{4}-\\d{2}-\\d{2}$")
        let range = NSRange(dateString.startIndex..., in: dateString)
        XCTAssertNotNil(regex.firstMatch(in: dateString, range: range))
    }
    
    func testDateStringFromSpecificDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: "2024-01-15")!
        
        XCTAssertEqual(dateString(from: date), "2024-01-15")
    }
    
    // MARK: - timeString Tests
    
    func testTimeStringFormat() {
        let date = Date()
        let result = timeString(from: date)
        
        // 验证格式 HH:mm:ss
        let regex = try! NSRegularExpression(pattern: "^\\d{2}:\\d{2}:\\d{2}$")
        let range = NSRange(result.startIndex..., in: result)
        XCTAssertNotNil(regex.firstMatch(in: result, range: range))
    }
    
    // MARK: - shortTimeString Tests
    
    func testShortTimeStringFormat() {
        let date = Date()
        let result = shortTimeString(from: date)
        
        // 验证格式 HH:mm
        let regex = try! NSRegularExpression(pattern: "^\\d{2}:\\d{2}$")
        let range = NSRange(result.startIndex..., in: result)
        XCTAssertNotNil(regex.firstMatch(in: result, range: range))
    }
}
