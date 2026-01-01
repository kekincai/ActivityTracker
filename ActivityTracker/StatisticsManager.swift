import Foundation
import AppKit

class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()
    
    @Published var topApps: [AppStatistics] = []
    @Published var totalActiveTime: TimeInterval = 0
    @Published var totalIdleTime: TimeInterval = 0
    
    private let dataStore = DataStore.shared
    
    private init() {
        refresh()
    }
    
    func refresh() {
        dataStore.loadTodayData()
        calculateStatistics()
    }
    
    private func calculateStatistics() {
        let segments = dataStore.todaySummary.segments
        
        // Calculate totals
        totalActiveTime = segments.filter { $0.bundleId != AppSegment.idle }.reduce(0) { $0 + $1.durationSeconds }
        totalIdleTime = segments.filter { $0.bundleId == AppSegment.idle }.reduce(0) { $0 + $1.durationSeconds }
        
        // Group by app
        var appDurations: [String: (name: String, duration: TimeInterval)] = [:]
        
        for segment in segments where segment.bundleId != AppSegment.idle {
            if var existing = appDurations[segment.bundleId] {
                existing.duration += segment.durationSeconds
                appDurations[segment.bundleId] = existing
            } else {
                appDurations[segment.bundleId] = (segment.appName, segment.durationSeconds)
            }
        }
        
        // Convert to AppStatistics and sort
        topApps = appDurations.map { bundleId, info in
            var stats = AppStatistics(
                bundleId: bundleId,
                appName: info.name,
                totalDuration: info.duration
            )
            stats.icon = getAppIcon(bundleId: bundleId)
            return stats
        }
        .sorted { $0.totalDuration > $1.totalDuration }
        .prefix(8)
        .map { $0 }
    }
    
    private func getAppIcon(bundleId: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
