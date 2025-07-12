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
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var dataService: RestaurantDataService
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // NYC
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedRestaurant: Restaurant?
    @State private var showingDetail = false
    @State private var isLoadingRestaurants = false
    @State private var currentRestaurants: [Restaurant] = []
    @State private var lastRegionUpdate = Date()
    @State private var regionUpdateTimer: Timer?
    @State private var showingLocationAlert = false
    
    // Performance optimization constants
    private let maxVisibleRestaurants = 50
    private let regionUpdateDebounce = 0.8 // seconds - increased for better performance
    private let minRegionChangeThreshold = 0.005 // degrees - more sensitive
    private let minZoomLevelForRestaurants = 0.05 // Only show restaurants when zoomed in enough
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: currentRestaurants) { restaurant in
                MapAnnotation(coordinate: restaurant.coordinate) {
                    RestaurantAnnotationView(restaurant: restaurant) {
                        print("📍 Restaurant selected: \(restaurant.name)")
                        // Ensure we're on the main thread and set the restaurant first
                        DispatchQueue.main.async {
                            selectedRestaurant = restaurant
                            // Small delay to ensure the restaurant is set before showing sheet
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                showingDetail = true
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onChange(of: region.center.latitude) { _ in
                handleRegionChange()
            }
            .onChange(of: region.center.longitude) { _ in
                handleRegionChange()
            }
            .onChange(of: region.span.latitudeDelta) { _ in
                handleRegionChange()
            }
            .onChange(of: region.span.longitudeDelta) { _ in
                handleRegionChange()
            }
            
            // Location button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: centerOnUserLocation) {
                        ZStack {
                            Circle()
                                .fill(locationButtonColor)
                                .frame(width: 50, height: 50)
                                .shadow(radius: 4)
                            
                            if locationManager.isRequestingLocation {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: locationButtonIcon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(locationManager.isRequestingLocation)
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
            
            // Restaurant count indicator
            if !currentRestaurants.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Text("\(currentRestaurants.count) restaurants")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                }
            }
            
            // Zoom instruction when no restaurants are shown
            if currentRestaurants.isEmpty && !isLoadingRestaurants && isZoomedOut() {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Zoom in to see restaurants")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        Spacer()
                    }
                    .padding(.bottom, 100) // Above location button
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let restaurant = selectedRestaurant {
                NavigationView {
                    RestaurantDetailView(restaurant: restaurant)
                        .navigationBarItems(trailing: Button("Done") {
                            print("🏪 Closing restaurant detail view")
                            showingDetail = false
                            selectedRestaurant = nil
                        })
                }
            }
        }
        .onChange(of: selectedRestaurant) { restaurant in
            if let restaurant = restaurant {
                print("🏪 selectedRestaurant changed to: \(restaurant.name)")
            } else {
                print("🏪 selectedRestaurant cleared")
            }
        }
        .alert("Location Access", isPresented: $showingLocationAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("ABCEats needs location access to show restaurants near you. Please enable location services in Settings.")
        }
        .onAppear {
            locationManager.requestLocationPermission()
            // Don't load restaurants immediately - wait for user interaction
        }
        .onChange(of: locationManager.location) { location in
            if let location = location {
                // Only update region if we're not currently loading location
                if !locationManager.isRequestingLocation {
                    region.center = location.coordinate
                }
            }
        }
        .onChange(of: locationManager.errorMessage) { errorMessage in
            if errorMessage != nil {
                showingLocationAlert = true
            }
        }
        .onDisappear {
            regionUpdateTimer?.invalidate()
            regionUpdateTimer = nil
        }
    }
    
    private var locationButtonColor: Color {
        if locationManager.isRequestingLocation {
            return .orange
        } else if locationManager.canAccessLocation() {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var locationButtonIcon: String {
        if locationManager.isRequestingLocation {
            return "location"
        } else if locationManager.canAccessLocation() {
            return "location.fill"
        } else {
            return "location.slash"
        }
    }
    
    private func handleRegionChange() {
        // Cancel previous timer
        regionUpdateTimer?.invalidate()
        
        // Check if we're zoomed in enough to show restaurants
        if isZoomedOut() {
            // Clear restaurants if zoomed out too far
            if !currentRestaurants.isEmpty {
                currentRestaurants.removeAll()
            }
            return
        }
        
        // Debounce region updates to prevent excessive API calls
        regionUpdateTimer = Timer.scheduledTimer(withTimeInterval: regionUpdateDebounce, repeats: false) { _ in
            loadRestaurantsForCurrentRegion()
        }
    }
    
    private func isZoomedOut() -> Bool {
        // Check if the current zoom level is too far out
        let maxSpan = max(region.span.latitudeDelta, region.span.longitudeDelta)
        return maxSpan > minZoomLevelForRestaurants
    }
    
    private func loadRestaurantsForCurrentRegion() {
        guard !isLoadingRestaurants else { return }
        guard !isZoomedOut() else { return }
        
        isLoadingRestaurants = true
        
        // Calculate radius based on current map span
        let radius = calculateRadiusFromRegion(region)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let allRestaurants = dataService.fetchRestaurantsNearLocation(
                center: region.center,
                radius: radius,
                limit: maxVisibleRestaurants * 2 // Get more than we need to have options
            )
            
            // Sort by distance and take the closest ones
            let sortedRestaurants = allRestaurants.sorted { restaurant1, restaurant2 in
                let distance1 = calculateDistance(from: region.center, to: restaurant1.coordinate)
                let distance2 = calculateDistance(from: region.center, to: restaurant2.coordinate)
                return distance1 < distance2
            }
            
            // Take only the closest restaurants up to our limit
            let limitedRestaurants = Array(sortedRestaurants.prefix(maxVisibleRestaurants))
            
            DispatchQueue.main.async {
                self.currentRestaurants = limitedRestaurants
                self.isLoadingRestaurants = false
                print("📍 Loaded \(limitedRestaurants.count) restaurants for current region (radius: \(String(format: "%.2f", radius)) miles)")
            }
        }
    }
    
    private func calculateDistance(from center: CLLocationCoordinate2D, to coordinate: CLLocationCoordinate2D) -> Double {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let restaurantLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return centerLocation.distance(from: restaurantLocation) / 1609.34 // Convert to miles
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
        
        // Cap at 2 miles to keep restaurants close and relevant
        return min(radius, 2.0)
    }
    
    private func centerOnUserLocation() {
        // Check if we have location access
        if !locationManager.canAccessLocation() {
            locationManager.requestLocationPermission()
            return
        }
        
        // If we already have a location, use it immediately
        if let location = locationManager.location {
            centerMapOnLocation(location)
        } else {
            // Request current location
            locationManager.getCurrentLocation()
        }
    }
    
    private func centerMapOnLocation(_ location: CLLocation) {
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = location.coordinate
            // Set span to show approximately 0.3 mile radius
            let span = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008) // ~0.3 mile
            region.span = span
        }
        
        // Load restaurants in 0.3-mile radius around user location
        DispatchQueue.global(qos: .userInitiated).async {
            let restaurants = dataService.fetchRestaurantsNearLocation(
                center: location.coordinate,
                radius: 0.3,
                limit: maxVisibleRestaurants
            )
            
            DispatchQueue.main.async {
                self.currentRestaurants = restaurants
                print("📍 Loaded \(restaurants.count) restaurants within 0.3 miles of user location")
            }
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