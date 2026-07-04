//
//  LocationManager.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 03/07/26.
//

import Foundation
import CoreLocation
import MapKit
import _MapKit_SwiftUI

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    var coordinate: CLLocationCoordinate2D = .userLocation
    var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    var updateCamera = false
    var showPin = true
    var manager: CLLocationManager = CLLocationManager()
    
    override init(){
        super.init()
        
        self.manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = /*kCLDistanceFilterNone*/ 10
        
        if self.manager.authorizationStatus == .notDetermined {
            
            self.manager.requestWhenInUseAuthorization()
            self.manager.startUpdatingLocation()
//            self.manager.requestLocation()
        } else if self.manager.authorizationStatus == .authorizedWhenInUse {
                self.manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Lokasi masuk: ", locations.last?.coordinate ?? "nil")
        locations.last.map {
            coordinate = $0.coordinate
            updateCamera = true
            showPin = true
            
            camera = .region(.init(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))
        }
    }

}

extension CLLocationCoordinate2D{
    static let userLocation = CLLocationCoordinate2D(latitude: -6.241, longitude: 106.657)
}

