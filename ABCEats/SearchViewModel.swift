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
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Debounce search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resetAndLoad()
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
        loadMoreRestaurants()
    }
    
    func loadMoreRestaurants() {
        guard let borough = selectedBorough, hasMoreData, !isLoadingMore else { return }
        
        isLoadingMore = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
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
    
    func clearFilters() {
        searchText = ""
        selectedBorough = nil
        resetAndLoad()
    }
    
    func getRestaurantCount() -> Int {
        guard let borough = selectedBorough else { return 0 }
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
        let cuisines = Set(filteredRestaurants.compactMap { $0.cuisine })
        return Array(cuisines).sorted()
    }
    
    func applyFilters() {
        resetAndLoad()
    }
    
    func clearAllFilters() {
        selectedGrade = nil
        selectedCuisine = nil
        minScore = nil
        maxScore = nil
        clearFilters()
    }
} 