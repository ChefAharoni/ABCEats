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
    
    @StateObject private var dataService = MockDataService()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var backgroundRefreshService = BackgroundRefreshService()
    
    @State private var selectedTab = 0
    @State private var showingFilters = false
    @State private var showingRefreshAlert = false
    
    var body: some View {
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
                mapView
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
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading restaurants...")
                .foregroundColor(.secondary)
                .padding(.top)
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
    
    private var mapView: some View {
        RestaurantMapView(restaurants: searchViewModel.filteredRestaurants, locationManager: locationManager)
            .navigationTitle("Restaurant Map")
            .navigationBarTitleDisplayMode(.large)
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
                
                Link("NYC Health Data Source", destination: URL(string: "https://a816-health.nyc.gov/ABCEatsRestaurants/#!/Search")!)
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
        // Register background tasks
        backgroundRefreshService.registerBackgroundTasks()
        backgroundRefreshService.scheduleBackgroundRefresh()
        
        // Load initial data if needed
        if restaurants.isEmpty {
            refreshData()
        }
    }
    
    private func refreshData() {
        dataService.fetchRestaurants(modelContext: modelContext)
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
