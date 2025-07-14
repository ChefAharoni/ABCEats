#!/usr/bin/env swift

import Foundation

// MARK: - Data Models
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

struct Violation: Codable {
    let code: String?
    let description: String
    let criticalFlag: String?
    let inspectionDate: Date?
}

struct Restaurant: Codable {
    let id: String
    let name: String
    let grade: String
    let foodType: String
    let address: String
    let borough: String
    let zipCode: String
    let latitude: Double
    let longitude: Double
    let lastUpdated: Date
    let phone: String?
    let cuisine: String?
    let inspectionDate: Date?
    let score: Int
    let violations: [Violation]
    
    init(
        id: String,
        name: String,
        grade: String,
        foodType: String,
        address: String,
        borough: String,
        zipCode: String,
        latitude: Double,
        longitude: Double,
        phone: String? = nil,
        cuisine: String? = nil,
        inspectionDate: Date? = nil,
        score: Int = 0,
        violations: [Violation] = []
    ) {
        self.id = id
        self.name = name
        self.grade = grade
        self.foodType = foodType
        self.address = address
        self.borough = borough
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
        self.lastUpdated = Date()
        self.phone = phone
        self.cuisine = cuisine
        self.inspectionDate = inspectionDate
        self.score = score
        self.violations = violations
    }
}

// MARK: - Data Generator
class RestaurantDataGenerator {
    private let baseURL = "https://data.cityofnewyork.us/resource/43nn-pn8j.json"
    private var allRestaurants: [Restaurant] = []
    
    func generateData() {
        print("🚀 Starting restaurant data generation...")
        print("📅 Generated on: \(Date())")
        
        // Clear existing data
        allRestaurants.removeAll()
        
        // Fetch all restaurants
        fetchAllRestaurants(offset: 0) { [weak self] success in
            if success {
                self?.saveDataToFile()
            } else {
                print("❌ Failed to generate restaurant data")
                exit(1)
            }
        }
    }
    
    private func fetchAllRestaurants(offset: Int, completion: @escaping (Bool) -> Void) {
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
            completion(false)
            return
        }
        
        print("🌐 Fetching restaurants \(offset + 1) to \(offset + limit)...")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 60.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(false)
                return
            }
            
            do {
                let restaurants = try JSONDecoder().decode([NYCRestaurantResponse].self, from: data)
                print("✅ Received \(restaurants.count) restaurants from API")
                self?.processRestaurants(restaurants, offset: offset, limit: limit, completion: completion)
            } catch {
                print("❌ Decoding error: \(error)")
                completion(false)
            }
        }.resume()
    }
    
    private func processRestaurants(_ restaurants: [NYCRestaurantResponse], offset: Int, limit: Int, completion: @escaping (Bool) -> Void) {
        print("🔄 Processing \(restaurants.count) restaurants from offset \(offset)...")
        
        // Group restaurants by CAMIS (unique restaurant identifier)
        let groupedRestaurants = Dictionary(grouping: restaurants) { $0.camis }
        print("📊 Grouped into \(groupedRestaurants.count) unique restaurants")
        
        var newRestaurantsCount = 0
        var validCoordinatesCount = 0
        var invalidCoordinatesCount = 0
        
        for (camis, inspections) in groupedRestaurants {
            // Get all violations for this restaurant
            let violations: [Violation] = inspections.compactMap { insp in
                guard let desc = insp.violationDescription, !desc.isEmpty else { return nil }
                return Violation(
                    code: insp.violationCode,
                    description: desc,
                    criticalFlag: insp.criticalFlag,
                    inspectionDate: parseDate(insp.inspectionDate)
                )
            }
            // Get the most recent inspection for summary fields
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
                let restaurant = createRestaurant(from: mostRecentInspection, camis: camis, violations: violations)
                allRestaurants.append(restaurant)
                newRestaurantsCount += 1
            } else {
                invalidCoordinatesCount += 1
            }
        }
        
        print("📈 Processed batch: \(newRestaurantsCount) new restaurants created")
        print("📍 Valid coordinates: \(validCoordinatesCount), Invalid: \(invalidCoordinatesCount)")
        
        // Continue with next batch if we got a full page
        if restaurants.count == limit {
            print("🔄 Continuing with next batch from offset \(offset + limit)")
            fetchAllRestaurants(offset: offset + limit, completion: completion)
        } else {
            print("🎉 Finished downloading all restaurants! Total: \(allRestaurants.count)")
            completion(true)
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
    
    private func saveDataToFile() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(allRestaurants)
            
            // Create Scripts directory if it doesn't exist
            let fileManager = FileManager.default
            let currentDirectory = fileManager.currentDirectoryPath
            let scriptsDirectory = "\(currentDirectory)/Scripts"
            
            if !fileManager.fileExists(atPath: scriptsDirectory) {
                try fileManager.createDirectory(atPath: scriptsDirectory, withIntermediateDirectories: true)
            }
            
            let outputPath = "\(scriptsDirectory)/restaurants_data.json"
            try data.write(to: URL(fileURLWithPath: outputPath))
            
            print("✅ Successfully saved \(allRestaurants.count) restaurants to \(outputPath)")
            print("📊 File size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
            
            // Also save to the app bundle location
            let appBundlePath = "\(currentDirectory)/ABCEats/restaurants_data.json"
            try data.write(to: URL(fileURLWithPath: appBundlePath))
            print("✅ Also saved to app bundle location: \(appBundlePath)")
            
        } catch {
            print("❌ Failed to save data: \(error)")
        }
    }
}

// MARK: - Main Execution
let generator = RestaurantDataGenerator()
generator.generateData()

// Keep the script running until completion
RunLoop.main.run() 