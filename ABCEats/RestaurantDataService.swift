//
//  RestaurantDataService.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import SwiftData
import Combine

class RestaurantDataService: ObservableObject {
    private let baseURL = "https://a816-health.nyc.gov/ABCEatsRestaurants/api/restaurants"
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    func fetchRestaurants(modelContext: ModelContext) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: baseURL) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [RestaurantResponse].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] restaurants in
                    self?.saveRestaurants(restaurants, to: modelContext)
                    self?.lastUpdateTime = Date()
                }
            )
            .store(in: &cancellables)
    }
    
    private func saveRestaurants(_ restaurantResponses: [RestaurantResponse], to modelContext: ModelContext) {
        // Clear existing data
        do {
            try modelContext.delete(model: Restaurant.self)
        } catch {
            print("Error clearing existing data: \(error)")
        }
        
        // Save new data
        for response in restaurantResponses {
            let restaurant = Restaurant(
                id: response.camis,
                name: response.dba,
                grade: response.grade ?? "N/A",
                foodType: response.cuisineDescription ?? "Unknown",
                address: "\(response.building ?? "") \(response.street ?? "")",
                borough: response.boro ?? "Unknown",
                zipCode: response.zipcode ?? "",
                latitude: Double(response.latitude ?? "") ?? 0.0,
                longitude: Double(response.longitude ?? "") ?? 0.0,
                phone: response.phone,
                cuisine: response.cuisineDescription,
                inspectionDate: parseDate(response.inspectionDate),
                score: Int(response.score ?? "")
            )
            modelContext.insert(restaurant)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving restaurants: \(error)")
        }
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

// API Response Models
struct RestaurantResponse: Codable {
    let camis: String
    let dba: String
    let boro: String
    let building: String?
    let street: String?
    let zipcode: String?
    let phone: String?
    let cuisineDescription: String?
    let inspectionDate: String?
    let action: String?
    let violationCode: String?
    let violationDescription: String?
    let criticalFlag: String?
    let score: String?
    let grade: String?
    let gradeDate: String?
    let recordDate: String?
    let inspectionType: String?
    let latitude: String?
    let longitude: String?
} 