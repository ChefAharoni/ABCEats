//
//  ABCEatsApp.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct ABCEatsApp: App {
    var sharedModelContainer: ModelContainer = {
        print("🏗️ Creating ModelContainer...")
        let schema = Schema([
            Restaurant.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer created successfully")
            return container
        } catch {
            print("❌ Failed to create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Register background tasks ONCE at app launch
        BackgroundRefreshService().registerBackgroundTasks()
        print("🚀 ABCEatsApp initializing...")
        // ... any other setup ...
        print("✅ ABCEatsApp initialization complete")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
