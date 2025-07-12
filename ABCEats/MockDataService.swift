//
//  MockDataService.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import SwiftData

class MockDataService: ObservableObject {
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    func fetchRestaurants(modelContext: ModelContext) {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.createMockRestaurants(modelContext: modelContext)
            self.isLoading = false
            self.lastUpdateTime = Date()
        }
    }
    
    private func createMockRestaurants(modelContext: ModelContext) {
        // Clear existing data
        do {
            try modelContext.delete(model: Restaurant.self)
        } catch {
            print("Error clearing existing data: \(error)")
        }
        
        let mockRestaurants = [
            Restaurant(
                id: "1",
                name: "Joe's Pizza",
                grade: "A",
                foodType: "Pizza",
                address: "123 Main St",
                borough: "Manhattan",
                zipCode: "10001",
                latitude: 40.7505,
                longitude: -73.9934,
                phone: "212-555-0101",
                cuisine: "Italian",
                inspectionDate: Date(),
                score: 8
            ),
            Restaurant(
                id: "2",
                name: "Sushi Palace",
                grade: "A",
                foodType: "Japanese",
                address: "456 Broadway",
                borough: "Manhattan",
                zipCode: "10013",
                latitude: 40.7205,
                longitude: -74.0050,
                phone: "212-555-0202",
                cuisine: "Japanese",
                inspectionDate: Date().addingTimeInterval(-86400),
                score: 7
            ),
            Restaurant(
                id: "3",
                name: "Burger Joint",
                grade: "B",
                foodType: "American",
                address: "789 5th Ave",
                borough: "Manhattan",
                zipCode: "10022",
                latitude: 40.7625,
                longitude: -73.9730,
                phone: "212-555-0303",
                cuisine: "American",
                inspectionDate: Date().addingTimeInterval(-172800),
                score: 12
            ),
            Restaurant(
                id: "4",
                name: "Taco Express",
                grade: "C",
                foodType: "Mexican",
                address: "321 Brooklyn Ave",
                borough: "Brooklyn",
                zipCode: "11201",
                latitude: 40.7025,
                longitude: -73.9870,
                phone: "718-555-0404",
                cuisine: "Mexican",
                inspectionDate: Date().addingTimeInterval(-259200),
                score: 18
            ),
            Restaurant(
                id: "5",
                name: "Thai Delight",
                grade: "A",
                foodType: "Thai",
                address: "654 Queens Blvd",
                borough: "Queens",
                zipCode: "11375",
                latitude: 40.7205,
                longitude: -73.8500,
                phone: "718-555-0505",
                cuisine: "Thai",
                inspectionDate: Date().addingTimeInterval(-345600),
                score: 6
            ),
            Restaurant(
                id: "6",
                name: "Pasta House",
                grade: "B",
                foodType: "Italian",
                address: "987 Bronx Ave",
                borough: "Bronx",
                zipCode: "10451",
                latitude: 40.8205,
                longitude: -73.9200,
                phone: "718-555-0606",
                cuisine: "Italian",
                inspectionDate: Date().addingTimeInterval(-432000),
                score: 14
            ),
            Restaurant(
                id: "7",
                name: "Chinese Garden",
                grade: "A",
                foodType: "Chinese",
                address: "147 Staten Island Rd",
                borough: "Staten Island",
                zipCode: "10301",
                latitude: 40.6405,
                longitude: -74.0750,
                phone: "718-555-0707",
                cuisine: "Chinese",
                inspectionDate: Date().addingTimeInterval(-518400),
                score: 9
            ),
            Restaurant(
                id: "8",
                name: "Deli Corner",
                grade: "B",
                foodType: "Deli",
                address: "258 Park Ave",
                borough: "Manhattan",
                zipCode: "10017",
                latitude: 40.7505,
                longitude: -73.9730,
                phone: "212-555-0808",
                cuisine: "Deli",
                inspectionDate: Date().addingTimeInterval(-604800),
                score: 11
            ),
            Restaurant(
                id: "9",
                name: "Seafood Shack",
                grade: "A",
                foodType: "Seafood",
                address: "369 Water St",
                borough: "Manhattan",
                zipCode: "10038",
                latitude: 40.7105,
                longitude: -74.0050,
                phone: "212-555-0909",
                cuisine: "Seafood",
                inspectionDate: Date().addingTimeInterval(-691200),
                score: 5
            ),
            Restaurant(
                id: "10",
                name: "BBQ Pit",
                grade: "C",
                foodType: "BBQ",
                address: "741 Atlantic Ave",
                borough: "Brooklyn",
                zipCode: "11238",
                latitude: 40.6805,
                longitude: -73.9700,
                phone: "718-555-1010",
                cuisine: "BBQ",
                inspectionDate: Date().addingTimeInterval(-777600),
                score: 20
            )
        ]
        
        // Save to model context
        for restaurant in mockRestaurants {
            modelContext.insert(restaurant)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving mock restaurants: \(error)")
        }
    }
} 