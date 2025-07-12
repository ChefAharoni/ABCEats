//
//  RestaurantDetailView.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @State private var region: MKCoordinateRegion
    
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        self._region = State(initialValue: MKCoordinateRegion(
            center: restaurant.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with grade
                headerSection
                
                // Map section
                mapSection
                
                // Details section
                detailsSection
                
                // Contact section
                if restaurant.phone != nil {
                    contactSection
                }
            }
            .padding()
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(restaurant.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(restaurant.foodType)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Grade badge
                gradeBadge
            }
            
            Text(restaurant.displayAddress)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var gradeBadge: some View {
        ZStack {
            Circle()
                .fill(gradeColor)
                .frame(width: 60, height: 60)
            
            Text(restaurant.grade)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    private var gradeColor: Color {
        switch restaurant.grade.uppercased() {
        case "A":
            return .green
        case "B":
            return .yellow
        case "C":
            return .red
        default:
            return .gray
        }
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
            
            Map(coordinateRegion: $region, annotationItems: [restaurant]) { restaurant in
                MapMarker(coordinate: restaurant.coordinate, tint: gradeColor)
            }
            .frame(height: 200)
            .cornerRadius(12)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            
            VStack(spacing: 8) {
                detailRow(title: "Borough", value: restaurant.borough)
                detailRow(title: "Zip Code", value: restaurant.zipCode)
                detailRow(title: "Food Type", value: restaurant.foodType)
                
                if let score = restaurant.score {
                    detailRow(title: "Health Score", value: "\(score)")
                }
                
                if let inspectionDate = restaurant.inspectionDate {
                    detailRow(title: "Inspection Date", value: formatDate(inspectionDate))
                }
                
                detailRow(title: "Last Updated", value: formatDate(restaurant.lastUpdated))
            }
        }
    }
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact")
                .font(.headline)
            
            if let phone = restaurant.phone {
                Button(action: {
                    if let url = URL(string: "tel:\(phone)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "phone")
                        Text(phone)
                        Spacer()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 