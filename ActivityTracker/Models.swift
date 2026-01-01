import Foundation
import AppKit

// MARK: - App Usage Segment
struct AppSegment: Identifiable, Codable, Equatable {
    let id: UUID
    var startTime: Date
    var endTime: Date
    let bundleId: String
    let appName: String
    var windowTitle: String?
    
    var durationSeconds: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    init(id: UUID = UUID(), startTime: Date, endTime: Date = Date(), bundleId: String, appName: String, windowTitle: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.bundleId = bundleId
        self.appName = appName
        self.windowTitle = windowTitle
    }
    
    static let idle = "idle"
    static let idleName = "Idle"
}

// MARK: - Daily Summary
struct DailySummary: Codable {
    let date: String
    var segments: [AppSegment]
    var totalActiveTime: TimeInterval
    var totalIdleTime: TimeInterval
    
    init(date: String, segments: [AppSegment] = []) {
        self.date = date
        self.segments = segments
        self.totalActiveTime = 0
        self.totalIdleTime = 0
    }
    
    mutating func recalculate() {
        totalActiveTime = segments.filter { $0.bundleId != AppSegment.idle }.reduce(0) { $0 + $1.durationSeconds }
        totalIdleTime = segments.filter { $0.bundleId == AppSegment.idle }.reduce(0) { $0 + $1.durationSeconds }
    }
}

// MARK: - App Statistics
struct AppStatistics: Identifiable {
    let id = UUID()
    let bundleId: String
    let appName: String
    var totalDuration: TimeInterval
    var icon: NSImage?
    
    var formattedDuration: String {
        formatDuration(totalDuration)
    }
}

// MARK: - Settings
struct TrackerSettings: Codable {
    var samplingInterval: Double = 1.0  // seconds
    var idleThreshold: Double = 300.0   // seconds (5 minutes)
    var enableWindowTitle: Bool = false
    var dataRetentionDays: Int = 30
    var launchAtLogin: Bool = false
    
    static let `default` = TrackerSettings()
}

// MARK: - Helpers
func formatDuration(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    let secs = Int(seconds) % 60
    
    if hours > 0 {
        return String(format: "%dh %dm", hours, minutes)
    } else if minutes > 0 {
        return String(format: "%dm %ds", minutes, secs)
    } else {
        return String(format: "%ds", secs)
    }
}

func dateString(from date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

func timeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: date)
}
