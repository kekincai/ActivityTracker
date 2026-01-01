import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var dataStore = DataStore.shared
    @ObservedObject var tracker = AppTracker.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var samplingInterval: Double
    @State private var idleThreshold: Double
    @State private var enableWindowTitle: Bool
    @State private var dataRetentionDays: Int
    @State private var launchAtLogin: Bool
    
    init() {
        let settings = DataStore.shared.settings
        _samplingInterval = State(initialValue: settings.samplingInterval)
        _idleThreshold = State(initialValue: settings.idleThreshold)
        _enableWindowTitle = State(initialValue: settings.enableWindowTitle)
        _dataRetentionDays = State(initialValue: settings.dataRetentionDays)
        _launchAtLogin = State(initialValue: settings.launchAtLogin)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.headline)
            
            Form {
                // Sampling Interval
                Section {
                    VStack(alignment: .leading) {
                        Text("Sampling Interval: \(String(format: "%.1f", samplingInterval))s")
                        Slider(value: $samplingInterval, in: 0.5...5.0, step: 0.5)
                    }
                } header: {
                    Text("Tracking")
                }
                
                // Idle Detection
                Section {
                    VStack(alignment: .leading) {
                        Text("Idle Threshold: \(Int(idleThreshold))s")
                        Slider(value: $idleThreshold, in: 60...600, step: 30)
                    }
                } header: {
                    Text("Idle Detection")
                }
                
                // Data
                Section {
                    Picker("Retention Days", selection: $dataRetentionDays) {
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                    }
                } header: {
                    Text("Data")
                }
                
                // System
                Section {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                } header: {
                    Text("System")
                }
                
                // Danger Zone
                Section {
                    Button("Clear Today's Data", role: .destructive) {
                        dataStore.clearTodayData()
                        StatisticsManager.shared.refresh()
                    }
                } header: {
                    Text("Danger Zone")
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 350, height: 450)
    }
    
    private func saveSettings() {
        dataStore.settings.samplingInterval = samplingInterval
        dataStore.settings.idleThreshold = idleThreshold
        dataStore.settings.enableWindowTitle = enableWindowTitle
        dataStore.settings.dataRetentionDays = dataRetentionDays
        dataStore.settings.launchAtLogin = launchAtLogin
        dataStore.saveSettings()
        
        // Restart tracking if running to apply new interval
        if tracker.isTracking {
            tracker.stopTracking()
            tracker.startTracking()
        }
        
        // Handle launch at login
        updateLaunchAtLogin(launchAtLogin)
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}

#Preview {
    SettingsView()
}
