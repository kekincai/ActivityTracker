import SwiftUI

struct DashboardView: View {
    @ObservedObject var tracker = AppTracker.shared
    @ObservedObject var stats = StatisticsManager.shared
    @ObservedObject var dataStore = DataStore.shared
    
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView
            
            // Stats Cards
            statsCardsView
            
            Divider()
            
            // App Rankings
            appRankingsView
            
            Divider()
            
            // Timeline
            timelineView
        }
        .padding(16)
        .frame(width: 360, height: 520)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            stats.refresh()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Activity Tracker")
                .font(.headline)
            
            Spacer()
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
            
            Menu {
                Button("Export CSV") { ExportManager.shared.exportCSV() }
                Button("Export JSON") { ExportManager.shared.exportJSON() }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Stats Cards
    private var statsCardsView: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Active",
                value: formatDuration(stats.totalActiveTime),
                icon: "clock.fill",
                color: .blue
            )
            
            StatCard(
                title: "Idle",
                value: formatDuration(stats.totalIdleTime),
                icon: "moon.fill",
                color: .gray
            )
            
            StatCard(
                title: "Status",
                value: tracker.isTracking ? "Running" : "Paused",
                icon: tracker.isTracking ? "play.fill" : "pause.fill",
                color: tracker.isTracking ? .green : .orange
            )
            .onTapGesture {
                tracker.toggleTracking()
            }
        }
    }
    
    // MARK: - App Rankings
    private var appRankingsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Apps")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if stats.topApps.isEmpty {
                Text("No data yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(stats.topApps.prefix(5)) { app in
                    AppRankRow(app: app, maxDuration: stats.topApps.first?.totalDuration ?? 1)
                }
            }
        }
    }
    
    // MARK: - Timeline
    private var timelineView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Activity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(dataStore.todaySummary.segments.suffix(10).reversed()) { segment in
                        TimelineRow(segment: segment)
                    }
                }
            }
            .frame(maxHeight: 120)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - App Rank Row
struct AppRankRow: View {
    let app: AppStatistics
    let maxDuration: TimeInterval
    
    var body: some View {
        HStack(spacing: 10) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app.fill")
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.caption)
                    .lineLimit(1)
                
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: geo.size.width * CGFloat(app.totalDuration / maxDuration))
                }
                .frame(height: 4)
            }
            
            Text(app.formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
    }
}

// MARK: - Timeline Row
struct TimelineRow: View {
    let segment: AppSegment
    
    var body: some View {
        HStack {
            Text(timeString(from: segment.startTime))
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Circle()
                .fill(segment.bundleId == AppSegment.idle ? Color.gray : Color.blue)
                .frame(width: 8, height: 8)
            
            Text(segment.appName)
                .font(.caption)
                .lineLimit(1)
            
            Spacer()
            
            Text(formatDuration(segment.durationSeconds))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    DashboardView()
}
