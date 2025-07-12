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
        // Debounce search text changes with longer delay for better performance
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)
        
        // Reset when borough changes
        $selectedBorough
            .sink { [weak self] _ in
                self?.resetAndLoad()
            }
            .store(in: &cancellables)
    }
    
    func getAvailableBoroughs() -> [String] {
        return dataService.getAvailableBoroughs()
    }
    
    func resetAndLoad() {
        currentOffset = 0
        filteredRestaurants = []
        hasMoreData = true
        allRestaurantsInBorough = []
        searchResults = []
        lastSearchText = ""
        lastBorough = ""
        
        // Cancel any ongoing search
        searchTask?.cancel()
        
        loadMoreRestaurants()
    }
    
    func loadMoreRestaurants() {
        guard let borough = selectedBorough, hasMoreData, !isLoadingMore else { return }
        
        isLoadingMore = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // If we have cached results, use them
            if !self.searchResults.isEmpty {
                let startIndex = self.currentOffset
                let endIndex = min(startIndex + self.pageSize, self.searchResults.count)
                
                if startIndex < self.searchResults.count {
                    let newRestaurants = Array(self.searchResults[startIndex..<endIndex])
                    
                    DispatchQueue.main.async {
                        self.isLoadingMore = false
                        self.filteredRestaurants.append(contentsOf: newRestaurants)
                        self.currentOffset += newRestaurants.count
                        self.hasMoreData = endIndex < self.searchResults.count
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoadingMore = false
                        self.hasMoreData = false
                    }
                }
                return
            }
            
            // Otherwise, fetch from data service
            let restaurants = self.dataService.fetchRestaurants(
                borough: borough,
                searchText: self.searchText,
                offset: self.currentOffset,
                limit: self.pageSize
            )
            
            DispatchQueue.main.async {
                self.isLoadingMore = false
                
                if restaurants.count < self.pageSize {
                    self.hasMoreData = false
                }
                
                if self.currentOffset == 0 {
                    // First page - replace all
                    self.filteredRestaurants = restaurants
                } else {
                    // Subsequent pages - append
                    self.filteredRestaurants.append(contentsOf: restaurants)
                }
                
                self.currentOffset += restaurants.count
            }
        }
    }
    
    private func performSearch() {
        guard let borough = selectedBorough else { return }
        
        // Cancel previous search task
        searchTask?.cancel()
        
        // If search text is empty, reset to show all restaurants in borough
        if searchText.isEmpty {
            resetAndLoad()
            return
        }
        
        // If borough changed, we need to reload all restaurants for that borough
        if borough != lastBorough {
            loadAllRestaurantsForBorough(borough)
            return
        }
        
        // If we already have all restaurants for this borough, perform local search
        if !allRestaurantsInBorough.isEmpty {
            performLocalSearch()
            return
        }
        
        // Otherwise, load all restaurants for the borough first
        loadAllRestaurantsForBorough(borough)
    }
    
    private func loadAllRestaurantsForBorough(_ borough: String) {
        searchTask = Task {
            // Load all restaurants for the borough (without search filter)
            let allRestaurants = dataService.fetchRestaurants(
                borough: borough,
                searchText: "",
                offset: 0,
                limit: 10000 // Large limit to get all restaurants
            )
            
            await MainActor.run {
                self.allRestaurantsInBorough = allRestaurants
                self.lastBorough = borough
                self.performLocalSearch()
            }
        }
    }
    
    private func performLocalSearch() {
        guard !searchText.isEmpty else {
            // Empty search - show first page of all restaurants
            currentOffset = 0
            searchResults = allRestaurantsInBorough
            loadMoreRestaurants()
            return
        }
        
        let searchLower = searchText.lowercased()
        
        // Perform local filtering
        let filtered = allRestaurantsInBorough.filter { restaurant in
            restaurant.name.lowercased().contains(searchLower) ||
            restaurant.address.lowercased().contains(searchLower) ||
            (restaurant.cuisine?.lowercased().contains(searchLower) ?? false) ||
            restaurant.borough.lowercased().contains(searchLower)
        }
        
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
        
        // Load first page
        loadMoreRestaurants()
    }
    
    func clearFilters() {
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