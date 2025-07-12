//
//  ContentView.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var dataService = RestaurantDataService()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var locationManager = LocationManager()
    
    @State private var selectedTab = 0
    @State private var showingFilters = false
    @State private var showingRefreshAlert = false
    @State private var showingBoroughPicker = false
    
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
            // Borough selector
            boroughSelector
            
            // Search bar (only show if borough is selected)
            if searchViewModel.selectedBorough != nil {
                searchBar
            }
            
            // Results
            if dataService.isLoading {
                loadingView
            } else if searchViewModel.selectedBorough == nil {
                boroughSelectionView
            } else if searchViewModel.filteredRestaurants.isEmpty && !searchViewModel.isLoadingMore {
                emptyStateView
            } else {
                restaurantListView
            }
        }
        .navigationTitle("NYC Restaurants")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if searchViewModel.selectedBorough != nil {
                    Button("Filters") {
                        showingFilters = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            SearchFiltersView(searchViewModel: searchViewModel)
        }
    }
    
    private var boroughSelector: some View {
        HStack {
            Text("Borough:")
                .fontWeight(.medium)
            
            Button(action: {
                showingBoroughPicker = true
            }) {
                HStack {
                    Text(searchViewModel.selectedBorough ?? "Select Borough")
                        .foregroundColor(searchViewModel.selectedBorough == nil ? .secondary : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
        .actionSheet(isPresented: $showingBoroughPicker) {
            ActionSheet(
                title: Text("Select Borough"),
                buttons: searchViewModel.getAvailableBoroughs().map { borough in
                    .default(Text(borough)) {
                        searchViewModel.selectedBorough = borough
                    }
                } + [.cancel()]
            )
        }
    }
    
    private var boroughSelectionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Select a Borough")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Choose a borough to browse restaurants")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Select Borough") {
                showingBoroughPicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
        List {
            ForEach(searchViewModel.filteredRestaurants, id: \.id) { restaurant in
                NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                    RestaurantListItemView(restaurant: restaurant)
                }
            }
            
            // Loading more indicator
            if searchViewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding()
            }
            
            // Load more button
            if searchViewModel.hasMoreData && !searchViewModel.isLoadingMore {
                Button("Load More") {
                    searchViewModel.loadMoreRestaurants()
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .listStyle(PlainListStyle())
        .onAppear {
            // Load initial data if needed
            if searchViewModel.filteredRestaurants.isEmpty && searchViewModel.selectedBorough != nil {
                searchViewModel.loadMoreRestaurants()
            }
        }
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
                
                HStack {
                    Text("Total Restaurants")
                    Spacer()
                    Text("\(dataService.totalRestaurantsLoaded)")
                        .foregroundColor(.secondary)
                }
                
                Button("Refresh Data") {
                    showingRefreshAlert = true
                }
                .foregroundColor(.blue)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Data Source")
                    Spacer()
                    Text("NYC Health")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
    
    private func setupApp() {
        print("🎯 Setting up app...")
        
        // Check if we need to download data
        let boroughs = searchViewModel.getAvailableBoroughs()
        if boroughs.isEmpty {
            print("📥 No data found, starting download...")
            dataService.downloadAllRestaurants { success in
                if success {
                    print("✅ Data download completed successfully")
                } else {
                    print("❌ Data download failed")
                }
            }
        } else {
            print("✅ Found \(boroughs.count) boroughs with data")
        }
    }
    
    private func refreshData() {
        dataService.downloadAllRestaurants { success in
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
}
