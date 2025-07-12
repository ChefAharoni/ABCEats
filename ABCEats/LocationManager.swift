//
//  LocationManager.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var isRequestingLocation = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location when user moves 10 meters
    }
    
    func requestLocationPermission() {
        print("📍 Requesting location permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        print("📍 Starting location updates...")
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        print("📍 Stopping location updates...")
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() {
        print("📍 Requesting current location...")
        isRequestingLocation = true
        errorMessage = nil
        
        // Check authorization status first
        switch authorizationStatus {
        case .notDetermined:
            requestLocationPermission()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable location services in Settings."
            isRequestingLocation = false
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        @unknown default:
            errorMessage = "Unknown authorization status"
            isRequestingLocation = false
        }
    }
    
    func canAccessLocation() -> Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        self.location = location
        self.isRequestingLocation = false
        self.errorMessage = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        isRequestingLocation = false
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                errorMessage = "Location access denied. Please enable location services in Settings."
            case .locationUnknown:
                errorMessage = "Unable to determine location. Please try again."
            case .network:
                errorMessage = "Network error. Please check your connection and try again."
            default:
                errorMessage = "Location error: \(clError.localizedDescription)"
            }
        } else {
            errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 Authorization status changed: \(status.rawValue)")
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location access granted")
            errorMessage = nil
            // Don't automatically start updates - wait for user to request location
        case .denied, .restricted:
            print("❌ Location access denied")
            errorMessage = "Location access denied. Please enable location services in Settings."
            isRequestingLocation = false
        case .notDetermined:
            print("⏳ Location permission not determined")
            errorMessage = nil
        @unknown default:
            print("❓ Unknown authorization status")
            errorMessage = "Unknown authorization status"
            isRequestingLocation = false
        }
    }
} 