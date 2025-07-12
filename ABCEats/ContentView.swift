//
//  ContentView.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var restaurants: [Restaurant]
    
    @StateObject private var dataService = RestaurantDataService()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var backgroundRefreshService = BackgroundRefreshService()
    
    @State private var selectedTab = 0
    @State private var showingFilters = false
    @State private var showingRefreshAlert = false
    
    var body: some View {
        let _ = print("🎯 ContentView body is being rendered!")
        
        TabView(selection: $selectedTab) {
            // Search Tab
            NavigationView {
                searchView
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
            .tag(0)
            
            // Map Tab
            NavigationView {
                RestaurantMapView(locationManager: locationManager, dataService: dataService)
            }
            .tabItem {
                Image(systemName: "map")
                Text("Map")
            }
            .tag(1)
            
            // Settings Tab
            NavigationView {
                settingsView
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(2)
        }
        .onAppear {
            print("🎯 ContentView appeared!")
            setupApp()
        }
        .onChange(of: restaurants) { _ in
            searchViewModel.updateRestaurants(restaurants)
        }
        .alert("Refresh Data", isPresented: $showingRefreshAlert) {
            Button("Refresh Now") {
                refreshData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to refresh the restaurant data from NYC Health?")
        }
        .alert("Error", isPresented: .constant(dataService.errorMessage != nil)) {
            Button("OK") {
                dataService.errorMessage = nil
            }
        } message: {
            if let errorMessage = dataService.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var searchView: some View {
        VStack {
            // Search bar
            searchBar
            
            // Results
            if dataService.isLoading {
                loadingView
            } else if searchViewModel.filteredRestaurants.isEmpty {
                emptyStateView
            } else {
                restaurantListView
            }
        }
        .navigationTitle("NYC Restaurants")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Filters") {
                    showingFilters = true
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            SearchFiltersView(searchViewModel: searchViewModel)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search restaurants...", text: $searchViewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchViewModel.searchText.isEmpty {
                Button("Clear") {
                    searchViewModel.searchText = ""
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(dataService.progressMessage)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if dataService.totalRestaurantsLoaded > 0 {
                Text("Total restaurants loaded: \(dataService.totalRestaurantsLoaded)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            if !dataService.progressMessage.isEmpty {
                Text("This may take a few minutes for the first load...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No restaurants found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Try adjusting your search criteria or filters")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                searchViewModel.clearFilters()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var restaurantListView: some View {
        List(searchViewModel.filteredRestaurants) { restaurant in
            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                RestaurantListItemView(restaurant: restaurant)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var settingsView: some View {
        List {
            Section("Data") {
                HStack {
                    Text("Last Updated")
                    Spacer()
                    if let lastUpdate = dataService.lastUpdateTime {
                        Text(formatDate(lastUpdate))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button("Refresh Data") {
                    showingRefreshAlert = true
                }
                .foregroundColor(.blue)
                
                Button("Test API Connection") {
                    dataService.testAPI()
                }
                .foregroundColor(.green)
                
                if dataService.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Location") {
                HStack {
                    Text("Location Access")
                    Spacer()
                    Text(locationStatusText)
                        .foregroundColor(.secondary)
                }
                
                if locationManager.authorizationStatus == .denied {
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link("NYC Health Data Source", destination: URL(string: "https://data.cityofnewyork.us/Health/DOHMH-New-York-City-Restaurant-Inspection-Results/43nn-pn8j")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "Enabled"
        case .denied, .restricted:
            return "Disabled"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func setupApp() {
        print("🚀 Setting up app...")
        
        // Register background tasks
        backgroundRefreshService.scheduleBackgroundRefresh()
        
        // Test API connection
        print("🧪 Testing API connection...")
        dataService.testAPI()
        
        // Load initial data if needed
        print("📊 Checking restaurants count: \(restaurants.count)")
        if restaurants.isEmpty {
            print("📱 No restaurants found, starting data fetch...")
            refreshData()
        } else {
            print("📱 Found \(restaurants.count) existing restaurants")
            // Check if data is stale (older than 24 hours)
            if let lastUpdate = dataService.lastUpdateTime {
                let hoursSinceUpdate = Calendar.current.dateComponents([.hour], from: lastUpdate, to: Date()).hour ?? 0
                if hoursSinceUpdate >= 24 {
                    print("🔄 Data is stale (\(hoursSinceUpdate) hours old), refreshing...")
                    refreshData()
                } else {
                    print("✅ Data is fresh (\(hoursSinceUpdate) hours old)")
                }
            } else {
                print("🔄 No last update time found, refreshing data...")
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        print("🔄 Starting data refresh...")
        dataService.fetchRestaurants(modelContext: modelContext) { success in
            if success {
                print("✅ Data refresh completed successfully")
            } else {
                print("❌ Data refresh failed")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
