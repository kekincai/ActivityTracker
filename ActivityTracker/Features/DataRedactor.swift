//
//  DataRedactor.swift
//  ActivityTracker
//
//  数据脱敏器
//  在保存前对敏感信息进行脱敏处理
//

import Foundation

/// 数据脱敏器
/// 使用正则表达式匹配并替换敏感信息（如邮箱、Token）
class DataRedactor {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = DataRedactor()
    
    // MARK: - Private Properties
    
    /// 编译后的正则表达式列表
    private var patterns: [NSRegularExpression] = []
    
    // MARK: - Initialization
    
    private init() {
        reloadPatterns()
    }
    
    // MARK: - Public Methods
    
    /// 重新加载脱敏规则
    func reloadPatterns() {
        let settings = DataStore.shared.settings
        patterns = settings.redactionPatterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        }
    }
    
    /// 对文本进行脱敏处理
    /// - Parameter text: 原始文本
    /// - Returns: 脱敏后的文本
    func redact(_ text: String?) -> String? {
        guard DataStore.shared.settings.enableDataRedaction,
              let text = text else { return text }
        
        var result = text
        
        // 应用所有脱敏规则
        for regex in patterns {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                range: range,
                withTemplate: "***"
            )
        }
        
        return result
    }
    
    /// 检查文本是否包含敏感信息
    /// - Parameter text: 待检查的文本
    /// - Returns: 是否包含敏感信息
    func containsSensitiveData(_ text: String) -> Bool {
        for regex in patterns {
            let range = NSRange(text.startIndex..., in: text)
            if regex.firstMatch(in: text, range: range) != nil {
                return true
            }
        }
        return false
    }
}
