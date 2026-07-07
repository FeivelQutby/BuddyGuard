//
//  LocationManager.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 03/07/26.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI // Replaced _MapKit_SwiftUI with standard SwiftUI

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    var coordinate: CLLocationCoordinate2D?
    var camera: MapCameraPosition = .automatic
    var updateCamera = false
    var showPin = true
    
    // Make the manager private so we don't accidentally mess with it outside this class
    private var manager: CLLocationManager = CLLocationManager()
    
    override init() {
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // Updates every 10 meters
        
        // Handle authorization safely
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        
        // Always start updating if we already have permission
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    // Listen for changes in authorization status
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    // Add this inside your LocationManager class
    func requestLocationPermission() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        
        print("Lokasi masuk: \(latestLocation.coordinate.latitude), \(latestLocation.coordinate.longitude)")
        
        coordinate = latestLocation.coordinate
        updateCamera = true
        showPin = true
        camera = .region(.init(center: latestLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))
    }
}

//extension CLLocationCoordinate2D {
//    // Default fallback location
//    static let userLocation = CLLocationCoordinate2D(latitude: -6.241, longitude: 106.657)
//}
