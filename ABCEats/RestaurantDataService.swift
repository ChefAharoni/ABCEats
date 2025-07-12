//
//  RestaurantDataService.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import SwiftData
import Combine
import CoreLocation // Added for CLLocationCoordinate2D

class RestaurantDataService: ObservableObject {
    private let baseURL = "https://data.cityofnewyork.us/resource/43nn-pn8j.json"
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    @Published var progressMessage: String = ""
    @Published var totalRestaurantsLoaded: Int = 0
    
    private var retryCount = 0
    private let maxRetries = 3
    
    // Location-based loading
    @Published var currentViewRestaurants: [Restaurant] = []
    private var allRestaurants: [Restaurant] = []
    
    // Test function to verify API is working
    func testAPI() {
        print("🧪 Testing API connection...")
        let testURL = "https://data.cityofnewyork.us/resource/43nn-pn8j.json?$limit=5"
        
        guard let url = URL(string: testURL) else {
            print("❌ Invalid test URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [NYCRestaurantResponse].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ API test failed: \(error)")
                    } else {
                        print("✅ API test successful")
                    }
                },
                receiveValue: { restaurants in
                    print("✅ API test received \(restaurants.count) restaurants")
                    if let first = restaurants.first {
                        print("📋 Sample restaurant: \(first.dba) - \(first.boro ?? "Unknown")")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func fetchRestaurants(modelContext: ModelContext, completion: ((Bool) -> Void)? = nil) {
        print("🔄 Starting restaurant data fetch...")
        isLoading = true
        errorMessage = nil
        progressMessage = "Starting data fetch..."
        totalRestaurantsLoaded = 0
        retryCount = 0
        
        // Clear existing data first
        clearExistingData(modelContext: modelContext)
        
        // Fetch all restaurants with pagination
        fetchAllRestaurants(modelContext: modelContext, offset: 0, completion: completion)
    }
    
    // New method for location-based loading
    func loadRestaurantsForRegion(center: CLLocationCoordinate2D, radius: Double, modelContext: ModelContext, completion: @escaping ([Restaurant]) -> Void) {
        print("📍 Loading restaurants for region: center(\(center.latitude), \(center.longitude)), radius: \(radius) miles")
        
        // If we have all restaurants loaded, filter from local data
        if !allRestaurants.isEmpty {
            let filteredRestaurants = filterRestaurantsByLocation(restaurants: allRestaurants, center: center, radius: radius)
            let limitedRestaurants = Array(filteredRestaurants.prefix(100))
            currentViewRestaurants = limitedRestaurants
            completion(limitedRestaurants)
            return
        }
        
        // Otherwise, fetch from API with location filter
        fetchRestaurantsForRegion(center: center, radius: radius, modelContext: modelContext, completion: completion)
    }
    
    private func fetchRestaurantsForRegion(center: CLLocationCoordinate2D, radius: Double, modelContext: ModelContext, completion: @escaping ([Restaurant]) -> Void) {
        let limit = 100
        let queryItems = [
            URLQueryItem(name: "$limit", value: "\(limit)"),
            URLQueryItem(name: "$order", value: "camis"),
            URLQueryItem(name: "$select", value: "camis,dba,boro,building,street,zipcode,phone,cuisine_description,inspection_date,action,violation_code,violation_description,critical_flag,score,grade,grade_date,record_date,inspection_type,latitude,longitude"),
            // Add location filter (approximate bounding box)
            URLQueryItem(name: "$where", value: "latitude is not null and longitude is not null and latitude != '0' and longitude != '0'")
        ]
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            errorMessage = "Invalid URL"
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [NYCRestaurantResponse].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        print("❌ Location-based API request failed: \(error)")
                        completion([])
                    }
                },
                receiveValue: { [weak self] responses in
                    guard let self = self else {
                        completion([])
                        return
                    }
                    print("✅ Received \(responses.count) restaurants for region")
                    let mappedRestaurants = responses.compactMap { resp -> Restaurant? in
                        guard let lat = Double(resp.latitude ?? ""),
                              let lon = Double(resp.longitude ?? ""),
                              lat != 0.0, lon != 0.0 else { return nil }
                        return self.createRestaurant(from: resp, camis: resp.camis)
                    }
                    let filteredRestaurants = self.filterRestaurantsByLocation(restaurants: mappedRestaurants, center: center, radius: radius)
                    let limitedRestaurants = Array(filteredRestaurants.prefix(100))
                    self.currentViewRestaurants = limitedRestaurants
                    completion(limitedRestaurants)
                }
            )
            .store(in: &cancellables)
    }
    
    private func filterRestaurantsByLocation(restaurants: [Restaurant], center: CLLocationCoordinate2D, radius: Double) -> [Restaurant] {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        return restaurants.filter { restaurant in
            let restaurantLocation = CLLocation(latitude: restaurant.latitude, longitude: restaurant.longitude)
            let distance = centerLocation.distance(from: restaurantLocation) / 1609.34 // Convert meters to miles
            return distance <= radius
        }
    }
    
    // Method to load restaurants around user's current location
    func loadRestaurantsAroundUserLocation(userLocation: CLLocationCoordinate2D, modelContext: ModelContext, completion: @escaping ([Restaurant]) -> Void) {
        let radius: Double = 0.5 // 0.5 miles
        loadRestaurantsForRegion(center: userLocation, radius: radius, modelContext: modelContext, completion: completion)
    }
    
    private func clearExistingData(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: Restaurant.self)
            try modelContext.save()
        } catch {
            print("Error clearing existing data: \(error)")
        }
    }
    
    private func fetchAllRestaurants(modelContext: ModelContext, offset: Int, completion: ((Bool) -> Void)? = nil) {
        let limit = 1000
        let queryItems = [
            URLQueryItem(name: "$limit", value: "\(limit)"),
            URLQueryItem(name: "$offset", value: "\(offset)"),
            URLQueryItem(name: "$order", value: "camis"),
            URLQueryItem(name: "$select", value: "camis,dba,boro,building,street,zipcode,phone,cuisine_description,inspection_date,action,violation_code,violation_description,critical_flag,score,grade,grade_date,record_date,inspection_type,latitude,longitude")
        ]
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            print("❌ Invalid URL")
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        print("🌐 Fetching from URL: \(url)")
        progressMessage = "Fetching restaurants \(offset + 1) to \(offset + limit)..."
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 60.0 // 60 second timeout for large datasets
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        print("📡 Making network request...")
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [NYCRestaurantResponse].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        let errorMessage: String
                        switch error {
                        case let decodingError as DecodingError:
                            errorMessage = "Data format error: \(decodingError.localizedDescription)"
                        case let urlError as URLError:
                            switch urlError.code {
                            case .timedOut:
                                errorMessage = "Request timed out. Please try again."
                            case .notConnectedToInternet:
                                errorMessage = "No internet connection. Please check your network."
                            default:
                                errorMessage = "Network error: \(urlError.localizedDescription)"
                            }
                        default:
                            errorMessage = "Unknown error: \(error.localizedDescription)"
                        }
                        
                        print("❌ API request failed: \(errorMessage)")
                        self?.errorMessage = errorMessage
                        self?.isLoading = false
                        
                        // Retry logic
                        if self?.retryCount ?? 0 < (self?.maxRetries ?? 3) {
                            self?.retryCount += 1
                            print("🔄 Retrying request (attempt \(self?.retryCount ?? 0)/\(self?.maxRetries ?? 3))...")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                self?.fetchAllRestaurants(modelContext: modelContext, offset: offset, completion: completion)
                            }
                        } else {
                            print("❌ Max retries reached")
                            completion?(false)
                        }
                    }
                },
                receiveValue: { [weak self] restaurants in
                    print("✅ Received \(restaurants.count) restaurants from API")
                    self?.processRestaurants(restaurants, modelContext: modelContext, offset: offset, limit: limit, completion: completion)
                }
            )
            .store(in: &cancellables)
    }
    
    private func processRestaurants(_ restaurants: [NYCRestaurantResponse], modelContext: ModelContext, offset: Int, limit: Int, completion: ((Bool) -> Void)?) {
        print("🔄 Processing \(restaurants.count) restaurants from offset \(offset)...")
        
        // Group restaurants by CAMIS (unique restaurant identifier)
        let groupedRestaurants = Dictionary(grouping: restaurants) { $0.camis }
        print("📊 Grouped into \(groupedRestaurants.count) unique restaurants")
        
        var newRestaurantsCount = 0
        var validCoordinatesCount = 0
        var invalidCoordinatesCount = 0
        
        for (camis, inspections) in groupedRestaurants {
            // Get the most recent inspection for each restaurant
            let mostRecentInspection = inspections
                .filter { $0.inspectionDate != nil }
                .sorted { 
                    guard let date1 = parseDate($0.inspectionDate),
                          let date2 = parseDate($1.inspectionDate) else { return false }
                    return date1 > date2
                }
                .first ?? inspections.first!
            
            // Only create restaurant if it has valid coordinates
            if let lat = Double(mostRecentInspection.latitude ?? ""),
               let lon = Double(mostRecentInspection.longitude ?? ""),
               lat != 0.0 && lon != 0.0 {
                validCoordinatesCount += 1
                print("📍 Valid coordinates: \(lat), \(lon) for restaurant: \(mostRecentInspection.dba)")
                let restaurant = createRestaurant(from: mostRecentInspection, camis: camis)
                modelContext.insert(restaurant)
                newRestaurantsCount += 1
            } else {
                invalidCoordinatesCount += 1
                print("❌ Invalid coordinates for restaurant: \(mostRecentInspection.dba) - lat: \(mostRecentInspection.latitude ?? "nil"), lon: \(mostRecentInspection.longitude ?? "nil")")
            }
        }
        
        print("📈 Processed batch: \(newRestaurantsCount) new restaurants created, \(validCoordinatesCount) valid coordinates, \(invalidCoordinatesCount) invalid coordinates")
        
        totalRestaurantsLoaded += newRestaurantsCount
        progressMessage = "Loaded \(totalRestaurantsLoaded) restaurants..."
        
        // Save current batch
        do {
            try modelContext.save()
            print("💾 Successfully saved \(newRestaurantsCount) restaurants to database")
        } catch {
            print("❌ Error saving restaurants: \(error)")
            errorMessage = "Error saving data: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        // Continue with next batch if we got a full page
        if restaurants.count == limit {
            print("🔄 Continuing with next batch from offset \(offset + limit)")
            fetchAllRestaurants(modelContext: modelContext, offset: offset + limit, completion: completion)
        } else {
            print("🎉 Finished loading all restaurants! Total: \(totalRestaurantsLoaded)")
            isLoading = false
            lastUpdateTime = Date()
            progressMessage = "Successfully loaded \(totalRestaurantsLoaded) restaurants"
            
            // Load all restaurants from database for local filtering
            loadAllRestaurantsFromDatabase(modelContext: modelContext)
            
            completion?(true)
        }
    }
    
    private func createRestaurant(from inspection: NYCRestaurantResponse, camis: String) -> Restaurant {
        print("🏪 Creating restaurant: \(inspection.dba)")
        
        let address = [inspection.building, inspection.street]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        
        let restaurant = Restaurant(
            id: camis,
            name: inspection.dba,
            grade: inspection.grade ?? "N/A",
            foodType: inspection.cuisineDescription ?? "Unknown",
            address: address.isEmpty ? "Address not available" : address,
            borough: inspection.boro ?? "Unknown",
            zipCode: inspection.zipcode ?? "",
            latitude: Double(inspection.latitude ?? "0") ?? 0.0,
            longitude: Double(inspection.longitude ?? "0") ?? 0.0,
            phone: inspection.phone,
            cuisine: inspection.cuisineDescription,
            inspectionDate: parseDate(inspection.inspectionDate),
            score: Int(inspection.score ?? "0")
        )
        
        print("✅ Created restaurant: \(restaurant.name) with grade: \(restaurant.grade)")
        return restaurant
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        // Handle different date formats from NYC API
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                print("📅 Successfully parsed date: \(dateString) -> \(date)")
                return date
            }
        }
        
        print("❌ Failed to parse date: \(dateString)")
        return nil
    }
    
    private func loadAllRestaurantsFromDatabase(modelContext: ModelContext) {
        print("📥 Loading all restaurants from database for local filtering...")
        let fetchDescriptor = FetchDescriptor<Restaurant>()
        do {
            allRestaurants = try modelContext.fetch(fetchDescriptor)
            print("✅ Loaded \(allRestaurants.count) restaurants from database")
        } catch {
            print("❌ Error fetching restaurants from database: \(error)")
        }
    }
}

// NYC API Response Models
struct NYCRestaurantResponse: Codable {
    let camis: String
    let dba: String
    let boro: String?
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
    
    enum CodingKeys: String, CodingKey {
        case camis, dba, boro, building, street, zipcode, phone
        case cuisineDescription = "cuisine_description"
        case inspectionDate = "inspection_date"
        case action, violationCode = "violation_code", violationDescription = "violation_description"
        case criticalFlag = "critical_flag", score, grade, gradeDate = "grade_date"
        case recordDate = "record_date", inspectionType = "inspection_type"
        case latitude, longitude
    }
} 