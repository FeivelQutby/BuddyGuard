//
//  RouteManager.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 04/07/26.
//

import Foundation
import MapKit

@Observable
class RouteManager {
    var routeToFriend: MKRoute?
    var routeFriendToDestination: MKRoute?
    var safePlaceName: String?
    var safePlaceAddress: String?
    var sourcePlaceName: String?
    
    //ETA
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH.mm"
        return f
    }()
    
    var eta: String?{
        guard let travelTime = routeFriendToDestination?.expectedTravelTime else {
            return ""
        }
        let etaDate = Date().addingTimeInterval(travelTime)
        return formatter.string(from: etaDate)
    }
    
    //Distance
    var distance: String?{
        guard let distance = routeFriendToDestination?.distance else {
            return ""
        }
        return String(format: "%.2f", distance/1000)
    }
    
    func getRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> MKRoute? {
        
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: source.latitude, longitude: source.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: destination.latitude, longitude: destination.longitude), address: nil)
        request.transportType = .walking
        
        do{
            let directions = try await MKDirections(request: request).calculate()
            return directions.routes.first
        }catch{
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func getSafePlaceInfo() async -> (name: String?, address: String?){
        let destination = CLLocation(latitude: DummyData.safeZone.safeAddress.latitude, longitude: DummyData.safeZone.safeAddress.longitude)
        
        guard let request = MKReverseGeocodingRequest(location: destination) else { return (nil, nil) }
        
        do{
            let mapItems = try await request.mapItems
            return (mapItems.first?.name, mapItems.first?.address?.fullAddress)
        }catch{
            print("Error reverse geocoding: \(error)")
            return (nil, nil)
        }
    }
    
    func getSourcePlaceName() async -> String?{
        let source = CLLocation(latitude: DummyData.user1.coordinate.latitude, longitude: DummyData.user1.coordinate.longitude)
        
        guard let request = MKReverseGeocodingRequest(location: source) else { return "" }
        
        do{
            let mapItems = try await request.mapItems
            return mapItems.first?.name
        }catch{
            print("Error reverse geocoding: \(error)")
            return ""
        }
    }
}

