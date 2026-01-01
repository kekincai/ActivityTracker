import Foundation

class DataStore: ObservableObject {
    static let shared = DataStore()
    
    private let fileManager = FileManager.default
    private var dataDirectory: URL
    
    @Published var todaySummary: DailySummary
    @Published var settings: TrackerSettings
    
    private init() {
        // Setup data directory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        dataDirectory = appSupport.appendingPathComponent("ActivityTracker", isDirectory: true)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        
        // Load today's data
        let today = dateString()
        todaySummary = DailySummary(date: today)
        settings = TrackerSettings.default
        
        loadTodayData()
        loadSettings()
    }
    
    // MARK: - File Paths
    private func dataFilePath(for date: String) -> URL {
        dataDirectory.appendingPathComponent("segments_\(date).json")
    }
    
    private var settingsFilePath: URL {
        dataDirectory.appendingPathComponent("settings.json")
    }
    
    // MARK: - Load Data
    func loadTodayData() {
        let today = dateString()
        let filePath = dataFilePath(for: today)
        
        guard fileManager.fileExists(atPath: filePath.path) else {
            todaySummary = DailySummary(date: today)
            return
        }
        
        do {
            let data = try Data(contentsOf: filePath)
            todaySummary = try JSONDecoder().decode(DailySummary.self, from: data)
        } catch {
            print("Failed to load data: \(error)")
            todaySummary = DailySummary(date: today)
        }
    }
    
    func loadSettings() {
        guard fileManager.fileExists(atPath: settingsFilePath.path) else { return }
        
        do {
            let data = try Data(contentsOf: settingsFilePath)
            settings = try JSONDecoder().decode(TrackerSettings.self, from: data)
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    // MARK: - Save Data
    func saveTodayData() {
        let filePath = dataFilePath(for: todaySummary.date)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(todaySummary)
            try data.write(to: filePath)
        } catch {
            print("Failed to save data: \(error)")
        }
    }
    
    func saveSettings() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settings)
            try data.write(to: settingsFilePath)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    // MARK: - Segment Management
    func addSegment(_ segment: AppSegment) {
        // Check if we need to start a new day
        let today = dateString()
        if todaySummary.date != today {
            saveTodayData()
            todaySummary = DailySummary(date: today)
        }
        
        todaySummary.segments.append(segment)
        todaySummary.recalculate()
        saveTodayData()
    }
    
    func updateLastSegment(endTime: Date) {
        guard !todaySummary.segments.isEmpty else { return }
        todaySummary.segments[todaySummary.segments.count - 1].endTime = endTime
        todaySummary.recalculate()
    }
    
    // MARK: - Export
    func exportToCSV() -> URL? {
        var csv = "ID,Start Time,End Time,Duration (s),Bundle ID,App Name,Window Title\n"
        
        for segment in todaySummary.segments {
            let row = "\(segment.id),\(segment.startTime),\(segment.endTime),\(Int(segment.durationSeconds)),\(segment.bundleId),\"\(segment.appName)\",\"\(segment.windowTitle ?? "")\"\n"
            csv += row
        }
        
        let exportPath = dataDirectory.appendingPathComponent("export_\(todaySummary.date).csv")
        
        do {
            try csv.write(to: exportPath, atomically: true, encoding: .utf8)
            return exportPath
        } catch {
            print("Failed to export CSV: \(error)")
            return nil
        }
    }
    
    func exportToJSON() -> URL? {
        let exportPath = dataDirectory.appendingPathComponent("export_\(todaySummary.date).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(todaySummary)
            try data.write(to: exportPath)
            return exportPath
        } catch {
            print("Failed to export JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear Data
    func clearTodayData() {
        let today = dateString()
        todaySummary = DailySummary(date: today)
        saveTodayData()
    }
}
