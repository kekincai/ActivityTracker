//
//  IdleDetector.swift
//  ActivityTracker
//
//  空闲检测器
//  使用 IOKit 检测系统空闲时间
//

import Foundation
import IOKit

/// 空闲检测器
/// 通过 IOKit 获取系统空闲时间，判断用户是否处于空闲状态
class IdleDetector {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = IdleDetector()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 获取系统空闲时间
    /// - Returns: 空闲时间（秒）
    /// - Note: 使用 IOKit 的 HIDIdleTime 属性
    func getSystemIdleTime() -> TimeInterval {
        var iterator: io_iterator_t = 0
        
        // 获取 IOHIDSystem 服务
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem"),
            &iterator
        ) == KERN_SUCCESS else {
            return 0
        }
        
        defer { IOObjectRelease(iterator) }
        
        // 获取第一个匹配的服务
        let entry = IOIteratorNext(iterator)
        guard entry != 0 else { return 0 }
        
        defer { IOObjectRelease(entry) }
        
        // 获取服务属性
        var unmanagedDict: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(
            entry,
            &unmanagedDict,
            kCFAllocatorDefault,
            0
        ) == KERN_SUCCESS,
              let dict = unmanagedDict?.takeRetainedValue() as? [String: Any] else {
            return 0
        }
        
        // 获取 HIDIdleTime 属性
        guard let idleTime = dict["HIDIdleTime"] as? Int64 else {
            return 0
        }
        
        // HIDIdleTime 单位是纳秒，转换为秒
        return TimeInterval(idleTime) / 1_000_000_000
    }
    
    /// 检查系统是否处于空闲状态
    /// - Parameter threshold: 空闲阈值（秒）
    /// - Returns: 是否空闲
    func isIdle(threshold: TimeInterval) -> Bool {
        return getSystemIdleTime() >= threshold
    }
}
