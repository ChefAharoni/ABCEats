//
//  Restaurant.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Restaurant {
    var id: String
    var name: String
    var grade: String
    var foodType: String
    var address: String
    var borough: String
    var zipCode: String
    var latitude: Double
    var longitude: Double
    var lastUpdated: Date
    var phone: String?
    var cuisine: String?
    var inspectionDate: Date?
    var score: Int?
    
    init(id: String, name: String, grade: String, foodType: String, address: String, borough: String, zipCode: String, latitude: Double, longitude: Double, phone: String? = nil, cuisine: String? = nil, inspectionDate: Date? = nil, score: Int? = nil) {
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
    }
    
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
}
