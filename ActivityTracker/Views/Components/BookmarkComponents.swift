//
//  BookmarkComponents.swift
//  ActivityTracker
//
//  书签相关组件
//  包括书签标签和添加书签的弹窗
//

import SwiftUI

// MARK: - Bookmark Tag

/// 书签标签
/// 在时间轴上显示的小标签
struct BookmarkTag: View {
    
    /// 书签数据
    let bookmark: Bookmark
    
    var body: some View {
        HStack(spacing: 4) {
            // 颜色指示点
            Circle()
                .fill(Color(bookmark.colorTag ?? "blue"))
                .frame(width: 6, height: 6)
            
            // 书签文本
            Text(bookmark.text)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Bookmark Sheet

/// 添加书签弹窗
struct BookmarkSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    /// 书签文本
    @State private var text = ""
    
    /// 选中的颜色
    @State private var selectedColor = "blue"
    
    /// 可选颜色列表
    let colors = ["blue", "green", "orange", "purple", "red"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("添加标记")
                .font(.headline)
            
            // 文本输入
            TextField("标记内容", text: $text)
                .textFieldStyle(.roundedBorder)
            
            // 颜色选择
            HStack {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(Color(color))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture { selectedColor = color }
                }
            }
            
            // 预设按钮
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(BookmarkManager.presets, id: \.text) { preset in
                        Button(preset.text) {
                            text = preset.text
                            selectedColor = preset.color
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            
            // 操作按钮
            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Button("添加") {
                    if !text.isEmpty {
                        BookmarkManager.shared.addBookmark(text: text, colorTag: selectedColor)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

// MARK: - Previews

#Preview("BookmarkTag") {
    HStack {
        BookmarkTag(bookmark: Bookmark(text: "开始工作", colorTag: "blue"))
        BookmarkTag(bookmark: Bookmark(text: "休息", colorTag: "green"))
    }
    .padding()
}

#Preview("BookmarkSheet") {
    BookmarkSheet()
}
