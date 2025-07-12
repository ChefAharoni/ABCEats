//
//  BackgroundRefreshService.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import SwiftData
import BackgroundTasks

class BackgroundRefreshService: ObservableObject {
    private let backgroundTaskIdentifier = "com.abceats.refresh"
    private let dataService = RestaurantDataService()
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = nextRefreshDate()
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }
    
    private func nextRefreshDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get tomorrow at 4:00 AM
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 4
        components.minute = 0
        components.second = 0
        
        guard let tomorrow4AM = calendar.date(from: components) else {
            return now.addingTimeInterval(24 * 60 * 60) // Fallback to 24 hours from now
        }
        
        return tomorrow4AM
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleBackgroundRefresh()
        
        // Create a task to track background execution
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform the refresh
        refreshData { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    private func refreshData(completion: @escaping (Bool) -> Void) {
        // Note: In a real app, you'd need to access ModelContext differently in background
        // For now, we'll just mark this as a placeholder
        print("Background refresh triggered")
        completion(true)
    }
} 