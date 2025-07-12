//
//  RestaurantMapView.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct RestaurantMapView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var dataService: RestaurantDataService
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // NYC
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedRestaurant: Restaurant?
    @State private var showingDetail = false
    @State private var isLoadingRestaurants = false
    @State private var userLocationCircle: MKCircle?
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: dataService.currentViewRestaurants) { restaurant in
                MapAnnotation(coordinate: restaurant.coordinate) {
                    RestaurantAnnotationView(restaurant: restaurant) {
                        selectedRestaurant = restaurant
                        showingDetail = true
                    }
                }
            }
            .ignoresSafeArea()
            .onChange(of: region.center.latitude) { _ in
                loadRestaurantsForCurrentRegion()
            }
            .onChange(of: region.center.longitude) { _ in
                loadRestaurantsForCurrentRegion()
            }
            .onChange(of: region.span.latitudeDelta) { _ in
                loadRestaurantsForCurrentRegion()
            }
            .onChange(of: region.span.longitudeDelta) { _ in
                loadRestaurantsForCurrentRegion()
            }
            
            // Location button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
            
            // Loading indicator
            if isLoadingRestaurants {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                    Text("Loading restaurants...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 4)
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let restaurant = selectedRestaurant {
                NavigationView {
                    RestaurantDetailView(restaurant: restaurant)
                        .navigationBarItems(trailing: Button("Done") {
                            showingDetail = false
                        })
                }
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
            loadRestaurantsForCurrentRegion()
        }
        .onChange(of: locationManager.location) { location in
            if let location = location {
                region.center = location.coordinate
            }
        }
    }
    
    private func loadRestaurantsForCurrentRegion() {
        guard !isLoadingRestaurants else { return }
        
        isLoadingRestaurants = true
        
        // Calculate radius based on current map span
        let radius = calculateRadiusFromRegion(region)
        
        dataService.loadRestaurantsForRegion(
            center: region.center,
            radius: radius,
            modelContext: modelContext
        ) { restaurants in
            DispatchQueue.main.async {
                isLoadingRestaurants = false
                print("📍 Loaded \(restaurants.count) restaurants for current region")
            }
        }
    }
    
    private func calculateRadiusFromRegion(_ region: MKCoordinateRegion) -> Double {
        // Calculate approximate radius in miles based on region span
        let latDelta = region.span.latitudeDelta
        let lonDelta = region.span.longitudeDelta
        
        // Convert to miles (approximate)
        let latMiles = latDelta * 69 // 1 degree latitude ≈ 69 miles
        let lonMiles = lonDelta * 54.6 // 1 degree longitude ≈ 54.6 miles at NYC latitude
        
        // Use the larger dimension as radius, with a minimum of 0.1 miles
        let radius = max(max(latMiles, lonMiles) / 2, 0.1)
        
        // Cap at 5 miles to prevent loading too many restaurants
        return min(radius, 5.0)
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.location {
            withAnimation {
                region.center = location.coordinate
                // Set span to show approximately 0.5 mile radius
                let span = MKCoordinateSpan(latitudeDelta: 0.014, longitudeDelta: 0.014) // ~0.5 mile
                region.span = span
            }
            
            // Load restaurants in 0.5-mile radius around user location
            dataService.loadRestaurantsAroundUserLocation(
                userLocation: location.coordinate,
                modelContext: modelContext
            ) { restaurants in
                print("📍 Loaded \(restaurants.count) restaurants within 0.5 miles of user location")
            }
        } else {
            locationManager.getCurrentLocation()
        }
    }
}

struct RestaurantAnnotationView: View {
    let restaurant: Restaurant
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(gradeColor)
                    .frame(width: 30, height: 30)
                
                Text(restaurant.grade)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
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
} 