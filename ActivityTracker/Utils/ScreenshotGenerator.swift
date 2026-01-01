//
//  ScreenshotGenerator.swift
//  ActivityTracker
//
//  截图生成器
//  将 SwiftUI View 渲染为 PNG 图片
//

import SwiftUI
import AppKit

/// 截图生成器
class ScreenshotGenerator {
    
    /// 将 SwiftUI View 渲染为 NSImage
    /// - Parameters:
    ///   - view: 要渲染的 SwiftUI View
    ///   - size: 渲染尺寸
    /// - Returns: 渲染后的 NSImage
    static func render<V: View>(_ view: V, size: CGSize) -> NSImage? {
        // 创建 NSHostingView
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: size)
        
        // 强制布局
        hostingView.layoutSubtreeIfNeeded()
        
        // 创建 bitmap
        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        
        // 渲染到 bitmap
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
        
        // 创建 NSImage
        let image = NSImage(size: size)
        image.addRepresentation(bitmapRep)
        
        return image
    }
    
    /// 将 NSImage 保存为 PNG 文件
    /// - Parameters:
    ///   - image: 要保存的图片
    ///   - url: 保存路径
    /// - Returns: 是否成功
    @discardableResult
    static func savePNG(_ image: NSImage, to url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return false
        }
        
        do {
            try pngData.write(to: url)
            return true
        } catch {
            print("Failed to save PNG: \(error)")
            return false
        }
    }
    
    /// 生成应用截图并保存
    /// - Parameter directory: 保存目录
    static func generateAppScreenshots(to directory: URL) {
        // 确保目录存在
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // 生成主界面截图
        let dashboardView = DashboardPreviewView()
        if let image = render(dashboardView, size: CGSize(width: 380, height: 560)) {
            let url = directory.appendingPathComponent("screenshot_dashboard.png")
            savePNG(image, to: url)
            print("Saved: \(url.path)")
        }
        
        // 生成设置界面截图
        let settingsView = SettingsPreviewView()
        if let image = render(settingsView, size: CGSize(width: 380, height: 480)) {
            let url = directory.appendingPathComponent("screenshot_settings.png")
            savePNG(image, to: url)
            print("Saved: \(url.path)")
        }
    }
}

// MARK: - Preview Views (带模拟数据)

/// 仪表盘预览视图（带模拟数据）
struct DashboardPreviewView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Activity Tracker")
                    .font(.headline)
                Spacer()
                Image(systemName: "bookmark.fill")
                Image(systemName: "gear")
                Image(systemName: "square.and.arrow.up")
            }
            
            // Stats Cards
            HStack(spacing: 10) {
                PreviewStatCard(title: "Active", value: "3h 25m", icon: "clock.fill", color: .blue)
                PreviewStatCard(title: "Focus", value: "1h 45m", icon: "target", color: .green)
                PreviewStatCard(title: "Status", value: "Running", icon: "play.fill", color: .green)
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
                PreviewAppRow(name: "Xcode", duration: "1h 30m", progress: 1.0, icon: "hammer.fill")
                PreviewAppRow(name: "Safari", duration: "45m", progress: 0.5, icon: "safari.fill")
                PreviewAppRow(name: "Terminal", duration: "35m", progress: 0.4, icon: "terminal.fill")
                PreviewAppRow(name: "Slack", duration: "25m", progress: 0.28, icon: "message.fill")
                PreviewAppRow(name: "Notes", duration: "15m", progress: 0.17, icon: "note.text")
            }
            
            Spacer()
        }
        .padding(16)
        .frame(width: 380, height: 560)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// 设置预览视图
struct SettingsPreviewView: View {
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
                    VStack(alignment: .leading) {
                        Text("采样间隔: 1.0s")
                            .font(.caption)
                        ProgressView(value: 0.2)
                    }
                    VStack(alignment: .leading) {
                        Text("空闲阈值: 300s")
                            .font(.caption)
                        ProgressView(value: 0.5)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("数据").font(.caption).foregroundColor(.secondary)
                    HStack {
                        Text("保留天数").font(.caption)
                        Spacer()
                        Text("90 天").font(.caption).foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("系统").font(.caption).foregroundColor(.secondary)
                    HStack {
                        Text("开机启动").font(.caption)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding()
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)
            
            Spacer()
            
            HStack {
                Button("Cancel") {}
                Spacer()
                Button("Save") {}
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 380, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Preview Helper Views

struct PreviewStatCard: View {
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

struct PreviewAppRow: View {
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
