#!/usr/bin/env swift
//
//  GenerateScreenshots.swift
//  生成所有 View 的截图
//
//  运行方式: swift GenerateScreenshots.swift
//

import Cocoa
import SwiftUI

// MARK: - Screenshot Generator

func renderViewToImage<V: View>(_ view: V, size: CGSize) -> NSImage? {
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = CGRect(origin: .zero, size: size)
    hostingView.layoutSubtreeIfNeeded()
    
    guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        return nil
    }
    
    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
    
    let image = NSImage(size: size)
    image.addRepresentation(bitmapRep)
    return image
}

func saveImageAsPNG(_ image: NSImage, to url: URL) -> Bool {
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        return false
    }
    
    do {
        try pngData.write(to: url)
        return true
    } catch {
        print("Error saving PNG: \(error)")
        return false
    }
}

// MARK: - Helper Components

struct MockStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(10)
    }
}

struct MockAppRow: View {
    let name: String
    let duration: String
    let progress: Double
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 22, height: 22)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: geo.size.width * progress)
                }
                .frame(height: 4)
            }
            
            Text(duration)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 55, alignment: .trailing)
        }
    }
}

struct MockTimelineRow: View {
    let time: String
    let app: String
    let duration: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(app)
                .font(.caption)
            
            Spacer()
            
            Text(duration)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - View Previews

/// 1. DashboardView - 主仪表盘
struct DashboardPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Activity Tracker")
                    .font(.headline)
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: "bookmark.fill")
                    Image(systemName: "gear")
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundColor(.secondary)
            }
            
            // Stats Cards
            HStack(spacing: 10) {
                MockStatCard(title: "Active", value: "3h 25m", icon: "clock.fill", color: .blue)
                MockStatCard(title: "Focus", value: "1h 45m", icon: "target", color: .green)
                MockStatCard(title: "Status", value: "Running", icon: "play.fill", color: .green)
            }
            
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(["排行", "时间轴", "分析"], id: \.self) { title in
                    Text(title)
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(title == "排行" ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            
            // App Rankings
            VStack(spacing: 6) {
                MockAppRow(name: "Xcode", duration: "1h 30m", progress: 1.0, icon: "hammer.fill")
                MockAppRow(name: "Safari", duration: "45m", progress: 0.5, icon: "safari.fill")
                MockAppRow(name: "Terminal", duration: "35m", progress: 0.4, icon: "terminal.fill")
                MockAppRow(name: "Slack", duration: "25m", progress: 0.28, icon: "message.fill")
                MockAppRow(name: "Notes", duration: "15m", progress: 0.17, icon: "note.text")
                MockAppRow(name: "Finder", duration: "10m", progress: 0.11, icon: "folder.fill")
            }
            
            Spacer()
        }
        .padding(16)
        .frame(width: 380, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// 2. TimelineView - 时间轴视图
struct TimelinePreview: View {
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Activity Tracker")
                    .font(.headline)
                Spacer()
            }
            
            // Stats Cards (简化)
            HStack(spacing: 10) {
                MockStatCard(title: "Active", value: "3h 25m", icon: "clock.fill", color: .blue)
                MockStatCard(title: "Focus", value: "1h 45m", icon: "target", color: .green)
                MockStatCard(title: "Status", value: "Running", icon: "play.fill", color: .green)
            }
            
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(["排行", "时间轴", "分析"], id: \.self) { title in
                    Text(title)
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(title == "时间轴" ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            
            // Bookmarks
            HStack(spacing: 8) {
                ForEach(["开始工作", "休息", "会议"], id: \.self) { text in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(text == "开始工作" ? Color.blue : (text == "休息" ? Color.green : Color.orange))
                            .frame(width: 6, height: 6)
                        Text(text)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Timeline
            VStack(spacing: 4) {
                MockTimelineRow(time: "14:30", app: "Xcode", duration: "25m", color: .blue)
                MockTimelineRow(time: "14:05", app: "Safari", duration: "15m", color: .blue)
                MockTimelineRow(time: "13:50", app: "Slack", duration: "10m", color: .orange)
                MockTimelineRow(time: "13:45", app: "Idle", duration: "5m", color: .gray)
                MockTimelineRow(time: "13:20", app: "Terminal", duration: "20m", color: .blue)
                MockTimelineRow(time: "13:00", app: "Xcode", duration: "18m", color: .blue)
            }
            
            Spacer()
        }
        .padding(16)
        .frame(width: 380, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// 3. AnalysisView - 分析视图
struct AnalysisPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Activity Tracker")
                    .font(.headline)
                Spacer()
            }
            
            // Stats Cards
            HStack(spacing: 10) {
                MockStatCard(title: "Active", value: "3h 25m", icon: "clock.fill", color: .blue)
                MockStatCard(title: "Focus", value: "1h 45m", icon: "target", color: .green)
                MockStatCard(title: "Status", value: "Running", icon: "play.fill", color: .green)
            }
            
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(["排行", "时间轴", "分析"], id: \.self) { title in
                    Text(title)
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(title == "分析" ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            
            // Fragmentation Card
            HStack {
                VStack(alignment: .leading) {
                    Text("碎片化指数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("42")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("切换次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("28")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
            
            // Top Interrupters
            VStack(alignment: .leading, spacing: 8) {
                Text("最常打断你的应用")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Slack")
                        .font(.caption)
                    Spacer()
                    Text("12 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Messages")
                        .font(.caption)
                    Spacer()
                    Text("8 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Mail")
                        .font(.caption)
                    Spacer()
                    Text("5 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .frame(width: 380, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// 4. SettingsView - 设置视图
struct SettingsPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.headline)
            
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(["基础", "功能", "隐私"], id: \.self) { title in
                    Text(title)
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(title == "基础" ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            
            // Settings Form
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("追踪").font(.caption).foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("采样间隔: 1.0s").font(.caption)
                        ProgressView(value: 0.1)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("空闲阈值: 300s").font(.caption)
                        ProgressView(value: 0.44)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("数据").font(.caption).foregroundColor(.secondary)
                    HStack {
                        Text("保留天数").font(.caption)
                        Spacer()
                        Text("90 天").font(.caption).foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("系统").font(.caption).foregroundColor(.secondary)
                    HStack {
                        Text("开机启动").font(.caption)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)
            
            Spacer()
            
            HStack {
                Button("Cancel") {}
                    .buttonStyle(.bordered)
                Spacer()
                Button("Save") {}
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 380, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// 5. BookmarkSheet - 书签弹窗
struct BookmarkSheetPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("添加标记")
                .font(.headline)
            
            TextField("标记内容", text: .constant("开始写代码"))
                .textFieldStyle(.roundedBorder)
            
            HStack {
                ForEach(["blue", "green", "orange", "purple", "red"], id: \.self) { color in
                    Circle()
                        .fill(Color(color == "blue" ? .blue : (color == "green" ? .green : (color == "orange" ? .orange : (color == "purple" ? .purple : .red)))))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(color == "blue" ? Color.primary : Color.clear, lineWidth: 2)
                        )
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(["开始工作", "休息", "会议开始", "写周报", "学习"], id: \.self) { text in
                        Text(text)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
            
            HStack {
                Button("取消") {}
                    .buttonStyle(.bordered)
                Spacer()
                Button("添加") {}
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300, height: 220)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// 6. StatCard - 统计卡片组件
struct StatCardPreview: View {
    var body: some View {
        HStack(spacing: 16) {
            MockStatCard(title: "Active", value: "3h 25m", icon: "clock.fill", color: .blue)
            MockStatCard(title: "Focus", value: "1h 45m", icon: "target", color: .green)
            MockStatCard(title: "Status", value: "Running", icon: "play.fill", color: .green)
        }
        .padding()
        .frame(width: 380, height: 100)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Main

struct ViewConfig {
    let name: String
    let view: AnyView
    let size: CGSize
}

let views: [ViewConfig] = [
    ViewConfig(name: "dashboard", view: AnyView(DashboardPreview()), size: CGSize(width: 380, height: 420)),
    ViewConfig(name: "timeline", view: AnyView(TimelinePreview()), size: CGSize(width: 380, height: 420)),
    ViewConfig(name: "analysis", view: AnyView(AnalysisPreview()), size: CGSize(width: 380, height: 420)),
    ViewConfig(name: "settings", view: AnyView(SettingsPreview()), size: CGSize(width: 380, height: 400)),
    ViewConfig(name: "bookmark_sheet", view: AnyView(BookmarkSheetPreview()), size: CGSize(width: 300, height: 220)),
    ViewConfig(name: "stat_cards", view: AnyView(StatCardPreview()), size: CGSize(width: 380, height: 100)),
]

// 创建输出目录
let outputDir = "ActivityTracker/Assets/Screenshots"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

print("📸 Generating screenshots...")
print("")

var successCount = 0
for config in views {
    if let image = renderViewToImage(config.view, size: config.size) {
        let outputPath = "\(outputDir)/\(config.name).png"
        if saveImageAsPNG(image, to: URL(fileURLWithPath: outputPath)) {
            print("✅ \(config.name).png (\(Int(config.size.width))x\(Int(config.size.height)))")
            successCount += 1
        } else {
            print("❌ Failed to save: \(config.name).png")
        }
    } else {
        print("❌ Failed to render: \(config.name)")
    }
}

print("")
print("📁 Output directory: \(outputDir)")
print("✨ Generated \(successCount)/\(views.count) screenshots")
