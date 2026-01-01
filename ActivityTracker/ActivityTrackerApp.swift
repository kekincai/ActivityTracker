import SwiftUI

@main
struct ActivityTrackerApp: App {
    @StateObject private var tracker = AppTracker.shared
    @StateObject private var stats = StatisticsManager.shared
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(tracker)
                .environmentObject(stats)
        } label: {
            Image(systemName: "waveform.path.ecg")
        }
        .menuBarExtraStyle(.window)
    }
    
    init() {
        // Start tracking automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppTracker.shared.startTracking()
        }
    }
}
