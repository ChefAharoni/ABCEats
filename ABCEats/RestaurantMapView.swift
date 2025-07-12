//
//  RestaurantMapView.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import SwiftUI
import MapKit

struct RestaurantMapView: View {
    let restaurants: [Restaurant]
    @ObservedObject var locationManager: LocationManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // NYC
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedRestaurant: Restaurant?
    @State private var showingDetail = false
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: restaurants) { restaurant in
                MapAnnotation(coordinate: restaurant.coordinate) {
                    RestaurantAnnotationView(restaurant: restaurant) {
                        selectedRestaurant = restaurant
                        showingDetail = true
                    }
                }
            }
            .ignoresSafeArea()
            
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
        }
        .onChange(of: locationManager.location) { location in
            if let location = location {
                region.center = location.coordinate
            }
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.location {
            withAnimation {
                region.center = location.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
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