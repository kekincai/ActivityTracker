//
//  ActivityTrackerApp.swift
//  ActivityTracker
//
//  macOS 菜单栏应用入口
//  使用 AppDelegate 方式实现更稳定的 Popover
//

import SwiftUI
import AppKit

/// 应用程序主入口
@main
struct ActivityTrackerApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 使用空的 Settings scene，实际 UI 由 AppDelegate 管理
        Settings {
            EmptyView()
        }
    }
}

/// AppDelegate 负责管理菜单栏和 Popover
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    
    /// 状态栏项
    private var statusItem: NSStatusItem!
    
    /// Popover 窗口
    private var popover: NSPopover!
    
    /// 事件监听器（用于点击外部关闭）
    private var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "Activity Tracker")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // 创建 Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 560)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: ContentView())
        
        // 启动追踪
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppTracker.shared.startTracking()
        }
    }
    
    /// 切换 Popover 显示状态
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                closePopover()
            } else {
                showPopover(button)
            }
        }
    }
    
    /// 显示 Popover
    func showPopover(_ sender: NSView) {
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        
        // 添加事件监听，点击外部时关闭
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }
    
    /// 关闭 Popover
    func closePopover() {
        popover.performClose(nil)
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
