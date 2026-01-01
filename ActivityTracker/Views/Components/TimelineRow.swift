//
//  TimelineRow.swift
//  ActivityTracker
//
//  时间轴行组件
//  显示单个使用分段的信息
//

import SwiftUI

/// 时间轴行
/// 显示分段的时间、应用名称、窗口标题和时长
struct TimelineRow: View {
    
    /// 应用使用分段
    let segment: AppSegment
    
    var body: some View {
        HStack {
            // 开始时间
            Text(shortTimeString(from: segment.startTime))
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            // 状态指示点
            Circle()
                .fill(segmentColor)
                .frame(width: 8, height: 8)
            
            // 应用信息
            VStack(alignment: .leading, spacing: 1) {
                Text(segment.appName)
                    .font(.caption)
                    .lineLimit(1)
                
                // 窗口标题（如果有）
                if let title = segment.windowTitle, !title.isEmpty {
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 会议图标
            if segment.isMeeting {
                Image(systemName: "video.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            
            // 使用时长
            Text(formatDuration(segment.durationSeconds))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
    
    /// 根据分段状态返回对应颜色
    private var segmentColor: Color {
        if segment.isIdle { return .gray }
        if segment.isMeeting { return .orange }
        if let score = segment.engagementScore, score >= 70 { return .green }
        return .blue
    }
}

#Preview {
    VStack {
        TimelineRow(segment: AppSegment(
            startTime: Date(),
            bundleId: "com.apple.Safari",
            appName: "Safari",
            windowTitle: "Google - Safari"
        ))
        TimelineRow(segment: AppSegment(
            startTime: Date(),
            bundleId: "idle",
            appName: "Idle"
        ))
    }
    .padding()
}
