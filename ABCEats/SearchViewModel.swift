//
//  SearchViewModel.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedGrade = "All"
    @Published var selectedBorough = "All"
    @Published var selectedFoodType = "All"
    @Published var selectedZipCode = ""
    @Published var isSearching = false
    
    private var restaurants: [Restaurant] = []
    private var cancellables = Set<AnyCancellable>()
    
    var filteredRestaurants: [Restaurant] {
        var filtered = restaurants
        
        // Filter by search text (name and address)
        if !searchText.isEmpty {
            filtered = filtered.filter { restaurant in
                restaurant.name.localizedCaseInsensitiveContains(searchText) ||
                restaurant.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by grade
        if selectedGrade != "All" {
            filtered = filtered.filter { $0.grade == selectedGrade }
        }
        
        // Filter by borough
        if selectedBorough != "All" {
            filtered = filtered.filter { $0.borough == selectedBorough }
        }
        
        // Filter by food type
        if selectedFoodType != "All" {
            filtered = filtered.filter { $0.foodType == selectedFoodType }
        }
        
        // Filter by zip code
        if !selectedZipCode.isEmpty {
            filtered = filtered.filter { $0.zipCode == selectedZipCode }
        }
        
        return filtered
    }
    
    var availableGrades: [String] {
        ["All"] + Array(Set(restaurants.map { $0.grade })).sorted()
    }
    
    var availableBoroughs: [String] {
        ["All"] + Array(Set(restaurants.map { $0.borough })).sorted()
    }
    
    var availableFoodTypes: [String] {
        ["All"] + Array(Set(restaurants.map { $0.foodType })).sorted()
    }
    
    func updateRestaurants(_ restaurants: [Restaurant]) {
        self.restaurants = restaurants
    }
    
    func clearFilters() {
        searchText = ""
        selectedGrade = "All"
        selectedBorough = "All"
        selectedFoodType = "All"
        selectedZipCode = ""
    }
} 