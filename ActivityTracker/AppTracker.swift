import Foundation
import AppKit
import Combine

class AppTracker: ObservableObject {
    static let shared = AppTracker()
    
    @Published var isTracking = false
    @Published var currentApp: String = ""
    @Published var currentBundleId: String = ""
    
    private var timer: Timer?
    private var currentSegment: AppSegment?
    private let dataStore = DataStore.shared
    private let idleDetector = IdleDetector.shared
    
    private var wasIdle = false
    
    private init() {}
    
    // MARK: - Tracking Control
    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        
        // Start sampling timer
        let interval = dataStore.settings.samplingInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sample()
        }
        
        // Initial sample
        sample()
    }
    
    func stopTracking() {
        guard isTracking else { return }
        isTracking = false
        
        timer?.invalidate()
        timer = nil
        
        // Close current segment
        if var segment = currentSegment {
            segment.endTime = Date()
            dataStore.updateLastSegment(endTime: segment.endTime)
            dataStore.saveTodayData()
            currentSegment = nil
        }
    }
    
    func toggleTracking() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }
    
    // MARK: - Sampling
    private func sample() {
        let now = Date()
        let idleThreshold = dataStore.settings.idleThreshold
        
        // Check idle state
        let isCurrentlyIdle = idleDetector.isIdle(threshold: idleThreshold)
        
        var bundleId: String
        var appName: String
        
        if isCurrentlyIdle {
            bundleId = AppSegment.idle
            appName = AppSegment.idleName
        } else if let frontApp = NSWorkspace.shared.frontmostApplication {
            bundleId = frontApp.bundleIdentifier ?? "unknown"
            appName = frontApp.localizedName ?? "Unknown"
        } else {
            bundleId = "unknown"
            appName = "Unknown"
        }
        
        // Update published properties
        DispatchQueue.main.async {
            self.currentApp = appName
            self.currentBundleId = bundleId
        }
        
        // Handle segment logic
        if let segment = currentSegment {
            if segment.bundleId == bundleId {
                // Same app, update end time
                dataStore.updateLastSegment(endTime: now)
            } else {
                // App changed, close old segment and start new one
                dataStore.updateLastSegment(endTime: now)
                startNewSegment(bundleId: bundleId, appName: appName, at: now)
            }
        } else {
            // No current segment, start new one
            startNewSegment(bundleId: bundleId, appName: appName, at: now)
        }
        
        wasIdle = isCurrentlyIdle
    }
    
    private func startNewSegment(bundleId: String, appName: String, at time: Date) {
        let segment = AppSegment(
            startTime: time,
            endTime: time,
            bundleId: bundleId,
            appName: appName
        )
        currentSegment = segment
        dataStore.addSegment(segment)
    }
}
