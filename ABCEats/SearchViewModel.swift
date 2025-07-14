//
//  SearchViewModel.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedBorough: String?
    @Published var filteredRestaurants: [Restaurant] = []
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    
    private let dataService = RestaurantDataService()
    private var currentOffset = 0
    private let pageSize = 50
    private var cancellables = Set<AnyCancellable>()
    
    // Performance optimizations
    private var allRestaurantsInBorough: [Restaurant] = []
    private var searchResults: [Restaurant] = []
    private var lastSearchText = ""
    private var lastBorough = ""
    private var searchTask: Task<Void, Never>?
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Search with minimal throttle for responsiveness while preventing excessive searches
        $searchText
            .throttle(for: .milliseconds(50), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] newText in
                // Search immediately for any text change
                self?.performSearch()
            }
            .store(in: &cancellables)
        
        // Reset when borough changes and immediately load restaurants
        $selectedBorough
            .sink { [weak self] borough in
                print("🏛️ Borough changed to: \(borough ?? "nil")")
                if let borough = borough {
                    self?.resetAndLoadForBorough(borough)
                } else {
                    self?.resetAndLoad()
                }
            }
            .store(in: &cancellables)
    }
    
    func getAvailableBoroughs() -> [String] {
        let boroughs = dataService.getAvailableBoroughs()
        print("🏛️ Available boroughs: \(boroughs)")
        return boroughs
    }
    
    func resetAndLoad() {
        print("🔄 Resetting and clearing all data")
        currentOffset = 0
        filteredRestaurants = []
        hasMoreData = true
        allRestaurantsInBorough = []
        searchResults = []
        lastSearchText = ""
        lastBorough = ""
        
        // Cancel any ongoing search
        searchTask?.cancel()
    }
    
    func resetAndLoadForBorough(_ borough: String) {
        print("🏛️ Resetting and loading for borough: \(borough)")
        currentOffset = 0
        filteredRestaurants = []
        hasMoreData = true
        allRestaurantsInBorough = []
        searchResults = []
        lastSearchText = ""
        lastBorough = borough
        
        // Cancel any ongoing search
        searchTask?.cancel()
        
        // Check if data service has data
        let availableBoroughs = dataService.getAvailableBoroughs()
        print("🏛️ Available boroughs: \(availableBoroughs)")
        
        if availableBoroughs.isEmpty {
            print("⚠️ No boroughs available in data service")
            return
        }
        
        if !availableBoroughs.contains(borough) {
            print("⚠️ Borough '\(borough)' not found in available boroughs: \(availableBoroughs)")
            return
        }
        
        print("✅ Borough '\(borough)' found, loading restaurants...")
        
        // Immediately load the first page of restaurants for this borough
        loadMoreRestaurants()
    }
    
    func loadMoreRestaurants() {
        guard let borough = selectedBorough else { 
            print("❌ No borough selected, cannot load restaurants")
            return 
        }
        
        guard hasMoreData else { 
            print("❌ No more data available")
            return 
        }
        
        guard !isLoadingMore else { 
            print("⏳ Already loading more restaurants")
            return 
        }
        
        print("📋 Loading restaurants for borough: \(borough), offset: \(currentOffset)")
        print("📋 Search text: '\(searchText)', searchResults count: \(searchResults.count)")
        isLoadingMore = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // If we have cached results, use them
            if !self.searchResults.isEmpty {
                print("📋 Using cached search results")
                let startIndex = self.currentOffset
                let endIndex = min(startIndex + self.pageSize, self.searchResults.count)
                
                if startIndex < self.searchResults.count {
                    let newRestaurants = Array(self.searchResults[startIndex..<endIndex])
                    
                    DispatchQueue.main.async {
                        self.isLoadingMore = false
                        self.filteredRestaurants.append(contentsOf: newRestaurants)
                        self.currentOffset += newRestaurants.count
                        self.hasMoreData = endIndex < self.searchResults.count
                        print("✅ Loaded \(newRestaurants.count) restaurants from cache, total: \(self.filteredRestaurants.count)")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoadingMore = false
                        self.hasMoreData = false
                        print("✅ No more cached results")
                    }
                }
                return
            }
            
            // Otherwise, fetch from data service
            print("🌐 Fetching from data service...")
            let restaurants = self.dataService.fetchRestaurants(
                borough: borough,
                searchText: self.searchText,
                offset: self.currentOffset,
                limit: self.pageSize
            )
            
            print("📋 Data service returned \(restaurants.count) restaurants")
            
            DispatchQueue.main.async {
                self.isLoadingMore = false
                
                if restaurants.count < self.pageSize {
                    self.hasMoreData = false
                }
                
                if self.currentOffset == 0 {
                    // First page - replace all
                    self.filteredRestaurants = restaurants
                    print("✅ First page loaded: \(restaurants.count) restaurants")
                } else {
                    // Subsequent pages - append
                    self.filteredRestaurants.append(contentsOf: restaurants)
                    print("✅ Appended \(restaurants.count) restaurants, total: \(self.filteredRestaurants.count)")
                }
                
                self.currentOffset += restaurants.count
            }
        }
    }
    
    private func performSearch() {
        guard let borough = selectedBorough else { 
            print("❌ No borough selected for search")
            return 
        }
        
        print("🔍 Performing search for borough: \(borough), text: '\(searchText)'")
        print("🔍 Current state - allRestaurantsInBorough: \(allRestaurantsInBorough.count), lastBorough: \(lastBorough)")
        
        // Cancel previous search task
        searchTask?.cancel()
        
        // If search text is empty, reset to show all restaurants in borough
        if searchText.isEmpty {
            print("🔍 Empty search, resetting to show all restaurants")
            resetAndLoadForBorough(borough)
            return
        }
        
        // Update last search text
        lastSearchText = searchText
        
        // If borough changed, we need to reload all restaurants for that borough
        if borough != lastBorough {
            print("🔍 Borough changed, loading all restaurants for new borough")
            loadAllRestaurantsForBorough(borough)
            return
        }
        
        // If we already have all restaurants for this borough, perform local search
        if !allRestaurantsInBorough.isEmpty {
            print("🔍 Performing local search on \(allRestaurantsInBorough.count) restaurants")
            performLocalSearch()
            return
        }
        
        // Otherwise, load all restaurants for the borough first
        print("🔍 Loading all restaurants for borough first")
        loadAllRestaurantsForBorough(borough)
    }
    
    private func loadAllRestaurantsForBorough(_ borough: String) {
        print("📥 Loading all restaurants for borough: \(borough)")
        searchTask = Task {
            // Load all restaurants for the borough (without search filter)
            let allRestaurants = dataService.fetchRestaurants(
                borough: borough,
                searchText: "",
                offset: 0,
                limit: 10000 // Large limit to get all restaurants
            )
            
            print("📥 Loaded \(allRestaurants.count) total restaurants for borough: \(borough)")
            
            await MainActor.run {
                self.allRestaurantsInBorough = allRestaurants
                self.lastBorough = borough
                
                // If there's search text, perform search immediately
                if !self.searchText.isEmpty {
                    self.performLocalSearch()
                } else {
                    // Otherwise, show first page of all restaurants
                    self.currentOffset = 0
                    self.searchResults = allRestaurants
                    self.loadMoreRestaurants()
                }
            }
        }
    }
    
    private func performLocalSearch() {
        guard !searchText.isEmpty else {
            // Empty search - show first page of all restaurants
            print("🔍 Empty search, showing first page of all restaurants")
            currentOffset = 0
            searchResults = allRestaurantsInBorough
            loadMoreRestaurants()
            return
        }
        
        let searchLower = searchText.lowercased()
        print("🔍 Performing local search for: '\(searchText)'")
        
        // Perform local filtering with improved performance
        let filtered = allRestaurantsInBorough.filter { restaurant in
            restaurant.name.lowercased().contains(searchLower) ||
            restaurant.address.lowercased().contains(searchLower) ||
            (restaurant.cuisine?.lowercased().contains(searchLower) ?? false) ||
            restaurant.borough.lowercased().contains(searchLower)
        }
        
        print("🔍 Found \(filtered.count) matching restaurants")
        
        // Sort by relevance (exact matches first, then partial matches)
        let sortedResults = filtered.sorted { restaurant1, restaurant2 in
            let name1 = restaurant1.name.lowercased()
            let name2 = restaurant2.name.lowercased()
            
            // Exact name matches first
            if name1 == searchLower && name2 != searchLower {
                return true
            }
            if name2 == searchLower && name1 != searchLower {
                return false
            }
            
            // Then by name similarity
            return name1 < name2
        }
        
        searchResults = sortedResults
        currentOffset = 0
        hasMoreData = sortedResults.count > pageSize
        
        // Immediately update the UI with first page of results
        let firstPage = Array(sortedResults.prefix(pageSize))
        DispatchQueue.main.async {
            self.filteredRestaurants = firstPage
            print("✅ Updated UI with \(firstPage.count) search results")
        }
    }
    
    func clearFilters() {
        print("🧹 Clearing all filters")
        searchText = ""
        selectedBorough = nil
        resetAndLoad()
    }
    
    func getRestaurantCount() -> Int {
        guard let borough = selectedBorough else { return 0 }
        
        // If we have search results, return their count
        if !searchResults.isEmpty {
            return searchResults.count
        }
        
        // Otherwise, get count from data service
        return dataService.getRestaurantCount(borough: borough, searchText: searchText)
    }
    
    // MARK: - Filter Properties
    
    @Published var selectedGrade: String?
    @Published var selectedCuisine: String?
    @Published var minScore: Int?
    @Published var maxScore: Int?
    
    var availableGrades: [String] {
        return ["A", "B", "C", "N/A"]
    }
    
    var availableCuisines: [String] {
        let cuisines = Set(allRestaurantsInBorough.compactMap { $0.cuisine })
        return Array(cuisines).sorted()
    }
    
    func applyFilters() {
        // Apply additional filters to current search results
        var filtered = searchResults.isEmpty ? allRestaurantsInBorough : searchResults
        
        if let grade = selectedGrade {
            filtered = filtered.filter { $0.grade == grade }
        }
        
        if let cuisine = selectedCuisine {
            filtered = filtered.filter { $0.cuisine == cuisine }
        }
        
        if let minScore = minScore {
            filtered = filtered.filter { $0.score >= minScore }
        }
        
        if let maxScore = maxScore {
            filtered = filtered.filter { $0.score <= maxScore }
        }
        
        searchResults = filtered
        currentOffset = 0
        hasMoreData = filtered.count > pageSize
        
        // Load first page of filtered results
        loadMoreRestaurants()
    }
    
    func clearAllFilters() {
        selectedGrade = nil
        selectedCuisine = nil
        minScore = nil
        maxScore = nil
        clearFilters()
    }
} 