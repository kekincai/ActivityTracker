//
//  AppRankRow.swift
//  ActivityTracker
//
//  应用排行榜行组件
//  显示单个应用的使用统计
//

import SwiftUI

/// 应用排行榜行
/// 显示应用图标、名称、使用时长和进度条
struct AppRankRow: View {
    
    /// 应用统计数据
    let app: AppStatistics
    
    /// 最大使用时长（用于计算进度条比例）
    let maxDuration: TimeInterval
    
    var body: some View {
        HStack(spacing: 10) {
            // 应用图标
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 22, height: 22)
            } else {
                Image(systemName: "app.fill")
                    .frame(width: 22, height: 22)
            }
            
            // 应用名称和进度条
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(app.appName)
                        .font(.caption)
                        .lineLimit(1)
                    
                    // 活动标签图标
                    if let labelId = app.labelId,
                       let label = ActivityLabeler.shared.getLabel(by: labelId) {
                        Image(systemName: label.icon)
                            .font(.caption2)
                            .foregroundColor(Color(label.color))
                    }
                }
                
                // 进度条
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: maxDuration > 0 ? geo.size.width * CGFloat(app.totalDuration / maxDuration) : 0)
                }
                .frame(height: 4)
            }
            
            // 使用时长
            Text(app.formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 55, alignment: .trailing)
        }
    }
}

#Preview {
    VStack {
        AppRankRow(
            app: AppStatistics(bundleId: "com.apple.Safari", appName: "Safari", totalDuration: 3600),
            maxDuration: 3600
        )
        AppRankRow(
            app: AppStatistics(bundleId: "com.apple.dt.Xcode", appName: "Xcode", totalDuration: 1800),
            maxDuration: 3600
        )
    }
    .padding()
}
