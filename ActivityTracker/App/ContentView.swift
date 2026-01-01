//
//  ContentView.swift
//  ActivityTracker
//
//  应用主内容视图
//  作为 DashboardView 的容器
//

import SwiftUI

/// 主内容视图
/// 简单包装 DashboardView，便于后续扩展
struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
}
