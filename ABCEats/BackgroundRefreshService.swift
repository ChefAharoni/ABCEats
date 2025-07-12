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
        do {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
                self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
            print("✅ Background task registered successfully")
        } catch {
            print("⚠️ Background task registration failed: \(error)")
            // Don't let this block the app - background tasks are optional
        }
    }
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        
        // Schedule for 4am daily
        var dateComponents = DateComponents()
        dateComponents.hour = 4
        dateComponents.minute = 0
        
        // If it's past 4am today, schedule for tomorrow
        let calendar = Calendar.current
        var targetDate = calendar.nextDate(after: Date(), matching: dateComponents, matchingPolicy: .nextTime) ?? Date()
        
        // If we can't get a valid date, schedule for 4am tomorrow
        if targetDate <= Date() {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? Date()
        }
        
        request.earliestBeginDate = targetDate
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background refresh scheduled for \(targetDate)")
        } catch {
            print("⚠️ Could not schedule background refresh: \(error)")
        }
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("🔄 Background refresh started")
        
        // Set up task expiration
        task.expirationHandler = {
            print("⚠️ Background refresh expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform the refresh
        dataService.fetchRestaurants(modelContext: ModelContext(try! ModelContainer(for: Restaurant.self))) { success in
            if success {
                print("✅ Background refresh completed successfully")
                // Schedule the next refresh
                self.scheduleBackgroundRefresh()
            } else {
                print("❌ Background refresh failed")
            }
            task.setTaskCompleted(success: success)
        }
    }
} 