//
//  StatCard.swift
//  ActivityTracker
//
//  统计卡片组件
//  显示单个统计指标
//

import SwiftUI

/// 统计卡片
/// 用于显示活跃时间、专注时间、追踪状态等
struct StatCard: View {
    
    /// 卡片标题
    let title: String
    
    /// 显示的值
    let value: String
    
    /// SF Symbol 图标名称
    let icon: String
    
    /// 图标颜色
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            // 图标
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            // 值
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
            
            // 标题
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

#Preview {
    HStack {
        StatCard(title: "Active", value: "2h 30m", icon: "clock.fill", color: .blue)
        StatCard(title: "Focus", value: "1h 15m", icon: "target", color: .green)
        StatCard(title: "Status", value: "Running", icon: "play.fill", color: .green)
    }
    .padding()
}
