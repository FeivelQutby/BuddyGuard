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
    var currentStepIndex: Int = 0
    
    //Step Navigation
    var currentStep: MKRoute.Step?{
        guard let route = routeFriendToDestination else {
            return nil
        }
        guard currentStepIndex < route.steps.count else {
            return nil
        }
        let step = route.steps[currentStepIndex]
        if step.distance == 0 && currentStepIndex + 1 < route.steps.count{
            return route.steps[currentStepIndex + 1]
        }
        return step
    }
    
    func updateCurrentStep(location: CLLocationCoordinate2D){
        guard let route = routeFriendToDestination else {
            return
        }
        guard currentStepIndex < route.steps.count else {
            return
        }
        let step = route.steps[currentStepIndex]
        guard let endPoint = step.polyline.coordinates.last else {
            return
        }
        let startCoordinateStep = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let endCoordinateStep = CLLocation(latitude: endPoint.latitude, longitude: endPoint.longitude)
        let distanceToEnd =  endCoordinateStep.distance(from: startCoordinateStep)
        if distanceToEnd < 20{
            currentStepIndex += 1
        }
        
    }
    
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
    
    func getSafePlaceInfo(from place: CLLocationCoordinate2D) async -> (name: String?, address: String?){
        let destination = CLLocation(latitude: place.latitude, longitude: place.longitude)
        
        guard let request = MKReverseGeocodingRequest(location: destination) else { return (nil, nil) }
        
        do{
            let mapItems = try await request.mapItems
            return (mapItems.first?.name, mapItems.first?.address?.fullAddress)
        }catch{
            print("Error reverse geocoding: \(error)")
            return (nil, nil)
        }
    }
    
    func getSourcePlaceName(from source: CLLocationCoordinate2D) async -> String?{
        let location = CLLocation(latitude: source.latitude, longitude: source.longitude)
        
        guard let request = MKReverseGeocodingRequest(location: location) else { return "" }
        
        do{
            let mapItems = try await request.mapItems
            return mapItems.first?.name
        }catch{
            print("Error reverse geocoding: \(error)")
            return ""
        }
    }
}

extension MKPolyline{
    var coordinates: [CLLocationCoordinate2D]{
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
