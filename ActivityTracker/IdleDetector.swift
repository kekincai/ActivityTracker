import Foundation
import IOKit

class IdleDetector {
    static let shared = IdleDetector()
    
    private init() {}
    
    /// Returns the system idle time in seconds using IOKit
    func getSystemIdleTime() -> TimeInterval {
        var iterator: io_iterator_t = 0
        
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"), &iterator) == KERN_SUCCESS else {
            return 0
        }
        
        defer { IOObjectRelease(iterator) }
        
        let entry = IOIteratorNext(iterator)
        guard entry != 0 else { return 0 }
        
        defer { IOObjectRelease(entry) }
        
        var unmanagedDict: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &unmanagedDict, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = unmanagedDict?.takeRetainedValue() as? [String: Any] else {
            return 0
        }
        
        guard let idleTime = dict["HIDIdleTime"] as? Int64 else {
            return 0
        }
        
        // HIDIdleTime is in nanoseconds, convert to seconds
        return TimeInterval(idleTime) / 1_000_000_000
    }
    
    /// Check if system is idle based on threshold
    func isIdle(threshold: TimeInterval) -> Bool {
        return getSystemIdleTime() >= threshold
    }
}
