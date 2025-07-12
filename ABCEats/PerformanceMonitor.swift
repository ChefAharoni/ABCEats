//
//  PerformanceMonitor.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import os.log

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    private let logger = Logger(subsystem: "com.abceats", category: "Performance")
    
    private var startTimes: [String: CFAbsoluteTime] = [:]
    private var metrics: [String: [Double]] = [:]
    
    private init() {}
    
    func startTimer(for operation: String) {
        startTimes[operation] = CFAbsoluteTimeGetCurrent()
    }
    
    func endTimer(for operation: String) -> Double {
        guard let startTime = startTimes[operation] else {
            logger.warning("No start time found for operation: \(operation)")
            return 0.0
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        startTimes.removeValue(forKey: operation)
        
        // Store metric for averaging
        if metrics[operation] == nil {
            metrics[operation] = []
        }
        metrics[operation]?.append(duration)
        
        // Log performance
        logger.info("⏱️ \(operation): \(String(format: "%.3f", duration))s")
        
        return duration
    }
    
    func getAverageTime(for operation: String) -> Double {
        guard let times = metrics[operation], !times.isEmpty else { return 0.0 }
        return times.reduce(0, +) / Double(times.count)
    }
    
    func logMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
            logger.info("💾 Memory usage: \(String(format: "%.1f", memoryUsageMB)) MB")
        }
    }
    
    func logPerformanceSummary() {
        logger.info("📊 Performance Summary:")
        for (operation, times) in metrics {
            let average = getAverageTime(for: operation)
            let min = times.min() ?? 0.0
            let max = times.max() ?? 0.0
            logger.info("  \(operation): avg=\(String(format: "%.3f", average))s, min=\(String(format: "%.3f", min))s, max=\(String(format: "%.3f", max))s, count=\(times.count)")
        }
    }
    
    func resetMetrics() {
        metrics.removeAll()
        startTimes.removeAll()
    }
}

// MARK: - Convenience Extensions

extension PerformanceMonitor {
    func measure<T>(_ operation: String, block: () -> T) -> T {
        startTimer(for: operation)
        let result = block()
        endTimer(for: operation)
        return result
    }
    
    func measureAsync<T>(_ operation: String, block: @escaping () async -> T) async -> T {
        startTimer(for: operation)
        let result = await block()
        endTimer(for: operation)
        return result
    }
} 