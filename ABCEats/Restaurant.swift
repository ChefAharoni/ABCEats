//
//  Restaurant.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import CoreLocation

struct Violation: Codable, Equatable, Identifiable {
    let id: String // unique per violation (e.g., code + date)
    let code: String?
    let description: String
    let criticalFlag: String? // "Critical" or "Not Critical"
    let inspectionDate: Date?
    
    var isCritical: Bool {
        (criticalFlag?.lowercased() == "critical")
    }
}

struct Restaurant: Identifiable, Codable, Equatable {
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
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var gradeColor: String {
        switch grade.uppercased() {
        case "A":
            return "green"
        case "B":
            return "yellow"
        case "C":
            return "red"
        default:
            return "gray"
        }
    }
    
    var displayAddress: String {
        "\(address), \(borough), NY \(zipCode)"
    }
    
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
        lastUpdated: Date = Date(),
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
        self.lastUpdated = lastUpdated
        self.phone = phone
        self.cuisine = cuisine
        self.inspectionDate = inspectionDate
        self.score = score
        self.violations = violations
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool {
        return lhs.id == rhs.id
    }
}
