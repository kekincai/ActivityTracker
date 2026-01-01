//
//  TooltipView.swift
//  ActivityTracker
//
//  自定义 Tooltip 组件
//  用于在 NSPopover 中显示悬浮提示
//

import SwiftUI

/// Tooltip 修饰器
struct TooltipModifier: ViewModifier {
    let text: String
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovering = hovering
            }
            .overlay(alignment: .bottom) {
                if isHovering {
                    TooltipBubble(text: text)
                        .offset(y: 30)
                        .zIndex(100)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.easeOut(duration: 0.15), value: isHovering)
                }
            }
    }
}

/// Tooltip 气泡视图
struct TooltipBubble: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.8))
            .cornerRadius(4)
            .fixedSize()
    }
}

/// View 扩展，添加 tooltip 方法
extension View {
    func tooltip(_ text: String) -> some View {
        modifier(TooltipModifier(text: text))
    }
}
