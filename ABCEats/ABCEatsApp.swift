//
//  ABCEatsApp.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import SwiftUI
import BackgroundTasks

@main
struct ABCEatsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.abceats.refresh", using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        
        return true
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("🔄 Background refresh task started")
        
        // Schedule the next background refresh
        scheduleBackgroundRefresh()
        
        // Create a task to ensure the app gets background time
        task.expirationHandler = {
            print("⚠️ Background refresh task expired")
        }
        
        // Perform the background refresh
        let dataService = RestaurantDataService()
        dataService.downloadAllRestaurants { success in
            print("🔄 Background refresh completed: \(success ? "success" : "failed")")
            task.setTaskCompleted(success: success)
        }
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.abceats.refresh")
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) // 4 hours from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background refresh scheduled for 4 hours from now")
        } catch {
            print("❌ Failed to schedule background refresh: \(error)")
        }
    }
}
