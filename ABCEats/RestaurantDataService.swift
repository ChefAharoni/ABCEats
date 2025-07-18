//
//  RestaurantDataService.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import Combine
import CoreLocation

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
    
    // In-memory storage
    private var allRestaurants: [Restaurant] = []
    
    // UserDefaults keys
    private let restaurantsKey = "savedRestaurants"
    private let lastUpdateKey = "lastUpdateTime"
    
    init() {
        print("🏪 RestaurantDataService initializing...")
        loadRestaurantsFromStorage()
        
        // If no data in storage, try to load from bundled data
        if allRestaurants.isEmpty {
            print("📦 No data in storage, loading bundled data...")
            loadBundledData()
        } else {
            print("✅ Data already loaded from storage: \(allRestaurants.count) restaurants")
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadRestaurantsFromStorage() {
        if let data = UserDefaults.standard.data(forKey: restaurantsKey),
           let restaurants = try? JSONDecoder().decode([Restaurant].self, from: data) {
            allRestaurants = restaurants
            print("📱 Loaded \(restaurants.count) restaurants from storage")
        }
        
        if let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date {
            lastUpdateTime = lastUpdate
        }
    }
    
    private func loadBundledData() {
        guard let url = Bundle.main.url(forResource: "restaurants_data", withExtension: "json") else {
            print("⚠️ No bundled restaurant data found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("📦 Found bundled data file, size: \(data.count) bytes")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let restaurants = try decoder.decode([Restaurant].self, from: data)
            allRestaurants = restaurants
            
            print("📦 Successfully loaded \(restaurants.count) restaurants from bundled data")
            
            // Save to storage for future use
            saveRestaurantsToStorage()
            
        } catch {
            print("❌ Failed to load bundled data: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context)")
                case .keyNotFound(let key, let context):
                    print("❌ Key not found: \(key) at \(context)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type) at \(context)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: expected \(type) at \(context)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
        }
    }
    
    private func saveRestaurantsToStorage() {
        if let data = try? JSONEncoder().encode(allRestaurants) {
            UserDefaults.standard.set(data, forKey: restaurantsKey)
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
            print("💾 Saved \(allRestaurants.count) restaurants to storage")
        }
    }
    
    // MARK: - Background Data Download
    
    func downloadAllRestaurants(completion: ((Bool) -> Void)? = nil) {
        print("🔄 Starting background restaurant data download...")
        isLoading = true
        errorMessage = nil
        progressMessage = "Starting data download..."
        totalRestaurantsLoaded = 0
        retryCount = 0
        
        // Clear existing data first
        allRestaurants.removeAll()
        
        // Fetch all restaurants with pagination
        fetchAllRestaurants(offset: 0, completion: completion)
    }
    
    private func fetchAllRestaurants(offset: Int, completion: ((Bool) -> Void)? = nil) {
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
        progressMessage = "Downloading restaurants \(offset + 1) to \(offset + limit)..."
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 60.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
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
                                self?.fetchAllRestaurants(offset: offset, completion: completion)
                            }
                        } else {
                            print("❌ Max retries reached")
                            completion?(false)
                        }
                    }
                },
                receiveValue: { [weak self] restaurants in
                    print("✅ Received \(restaurants.count) restaurants from API")
                    self?.processRestaurants(restaurants, offset: offset, limit: limit, completion: completion)
                }
            )
            .store(in: &cancellables)
    }
    
    private func processRestaurants(_ restaurants: [NYCRestaurantResponse], offset: Int, limit: Int, completion: ((Bool) -> Void)?) {
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
                let violations: [Violation] = inspections.compactMap { inspection in
                    guard let desc = inspection.violationDescription, !desc.isEmpty else { return nil }
                    let code = inspection.violationCode
                    let date = parseDate(inspection.inspectionDate)
                    let id = [code ?? "", inspection.inspectionDate ?? "unknown"].joined(separator: "_")
                    return Violation(
                        id: id,
                        code: code,
                        description: desc,
                        criticalFlag: inspection.criticalFlag,
                        inspectionDate: date
                    )
                }
                let restaurant = createRestaurant(from: mostRecentInspection, camis: camis, violations: violations)
                allRestaurants.append(restaurant)
                newRestaurantsCount += 1
            } else {
                invalidCoordinatesCount += 1
            }
        }
        
        print("📈 Processed batch: \(newRestaurantsCount) new restaurants created")
        
        totalRestaurantsLoaded += newRestaurantsCount
        progressMessage = "Downloaded \(totalRestaurantsLoaded) restaurants..."
        
        // Save current batch
        saveRestaurantsToStorage()
        print("💾 Successfully saved \(newRestaurantsCount) restaurants to storage")
        
        // Continue with next batch if we got a full page
        if restaurants.count == limit {
            print("🔄 Continuing with next batch from offset \(offset + limit)")
            fetchAllRestaurants(offset: offset + limit, completion: completion)
        } else {
            print("🎉 Finished downloading all restaurants! Total: \(totalRestaurantsLoaded)")
            isLoading = false
            lastUpdateTime = Date()
            progressMessage = "Successfully downloaded \(totalRestaurantsLoaded) restaurants"
            completion?(true)
        }
    }
    
    private func createRestaurant(from inspection: NYCRestaurantResponse, camis: String, violations: [Violation]) -> Restaurant {
        let address = [inspection.building, inspection.street]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        
        return Restaurant(
            id: camis,
            name: inspection.dba,
            grade: inspection.grade ?? "N/A",
            foodType: inspection.cuisineDescription ?? "Unknown",
            address: address.isEmpty ? "Address not available" : address,
            borough: inspection.boro ?? "Unknown",
            zipCode: inspection.zipcode ?? "",
            latitude: Double(inspection.latitude ?? "0") ?? 0.0,
            longitude: Double(inspection.longitude ?? "0") ?? 0.0,
            lastUpdated: parseDate(inspection.recordDate) ?? Date(),
            phone: inspection.phone,
            cuisine: inspection.cuisineDescription,
            inspectionDate: parseDate(inspection.inspectionDate),
            score: Int(inspection.score ?? "0") ?? 0,
            violations: violations
        )
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    // MARK: - Search Methods
    
    func fetchRestaurants(borough: String, searchText: String = "", offset: Int = 0, limit: Int = 50) -> [Restaurant] {
        print("🔍 Fetching restaurants for borough: '\(borough)', search: '\(searchText)', offset: \(offset), limit: \(limit)")
        print("🔍 Total restaurants in memory: \(allRestaurants.count)")
        
        // Use a more efficient approach for large datasets
        let filteredRestaurants: [Restaurant]
        
        if searchText.isEmpty {
            // No search text - just filter by borough
            filteredRestaurants = allRestaurants.filter { $0.borough == borough }
            print("🔍 Filtered by borough only: \(filteredRestaurants.count) restaurants")
        } else {
            // With search text - use more efficient filtering
            let searchLower = searchText.lowercased()
            filteredRestaurants = allRestaurants.filter { restaurant in
                restaurant.borough == borough && (
                    restaurant.name.lowercased().contains(searchLower) ||
                    restaurant.address.lowercased().contains(searchLower) ||
                    (restaurant.cuisine?.lowercased().contains(searchLower) ?? false)
                )
            }
            print("🔍 Filtered by borough and search: \(filteredRestaurants.count) restaurants")
        }
        
        // Sort by name (only if we have a reasonable number of results)
        let sortedRestaurants = filteredRestaurants.count > 1000 ? 
            filteredRestaurants : 
            filteredRestaurants.sorted { $0.name < $1.name }
        
        // Apply pagination
        let startIndex = offset
        let endIndex = min(startIndex + limit, sortedRestaurants.count)
        
        if startIndex < sortedRestaurants.count {
            let result = Array(sortedRestaurants[startIndex..<endIndex])
            print("📋 Returning \(result.count) restaurants for borough: \(borough), offset: \(offset), total: \(sortedRestaurants.count)")
            return result
        }
        
        print("📋 No restaurants found for borough: \(borough)")
        return []
    }
    
    func getRestaurantCount(borough: String, searchText: String = "") -> Int {
        // Use the same efficient filtering logic as fetchRestaurants
        if searchText.isEmpty {
            // No search text - just count by borough
            return allRestaurants.filter { $0.borough == borough }.count
        } else {
            // With search text - use efficient filtering
            let searchLower = searchText.lowercased()
            return allRestaurants.filter { restaurant in
                restaurant.borough == borough && (
                    restaurant.name.lowercased().contains(searchLower) ||
                    restaurant.address.lowercased().contains(searchLower) ||
                    (restaurant.cuisine?.lowercased().contains(searchLower) ?? false)
                )
            }.count
        }
    }
    
    func getAvailableBoroughs() -> [String] {
        let boroughs = Set(allRestaurants.map { $0.borough })
        let sortedBoroughs = Array(boroughs).sorted()
        print("🏛️ Available boroughs: \(sortedBoroughs) (from \(allRestaurants.count) restaurants)")
        return sortedBoroughs
    }
    
    // MARK: - Location-based Methods
    
    func fetchRestaurantsNearLocation(center: CLLocationCoordinate2D, radius: Double, limit: Int = 100) -> [Restaurant] {
        return PerformanceMonitor.shared.measure("Location Search") {
            let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
            
            // Pre-calculate the bounding box for faster filtering
            let latDelta = radius / 69.0 // Convert miles to degrees (approximate)
            let lonDelta = radius / (54.6 * cos(center.latitude * .pi / 180)) // Adjust for latitude
            
            let minLat = center.latitude - latDelta
            let maxLat = center.latitude + latDelta
            let minLon = center.longitude - lonDelta
            let maxLon = center.longitude + lonDelta
            
            // First pass: filter by bounding box (much faster than distance calculation)
            let candidates = allRestaurants.filter { restaurant in
                restaurant.latitude >= minLat && restaurant.latitude <= maxLat &&
                restaurant.longitude >= minLon && restaurant.longitude <= maxLon
            }
            
            // Second pass: calculate exact distances for candidates and sort
            let nearbyRestaurants = candidates.compactMap { restaurant -> (Restaurant, Double)? in
                let restaurantLocation = CLLocation(latitude: restaurant.latitude, longitude: restaurant.longitude)
                let distance = centerLocation.distance(from: restaurantLocation) / 1609.34 // Convert to miles
                return distance <= radius ? (restaurant, distance) : nil
            }
            .sorted { $0.1 < $1.1 } // Sort by distance
            .prefix(limit)
            .map { $0.0 } // Extract just the restaurants
            
            return Array(nearbyRestaurants)
        }
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        allRestaurants.removeAll()
        UserDefaults.standard.removeObject(forKey: restaurantsKey)
        UserDefaults.standard.removeObject(forKey: lastUpdateKey)
        lastUpdateTime = nil
        print("🗑️ Cleared all restaurant data")
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