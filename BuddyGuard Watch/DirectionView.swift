//
//  DirectionView.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Benedicta Joyce Sutandyo on 07/07/26.
//

import SwiftUI
import MapKit
import WatchConnectivity

struct DirectionView: View {
    @State private var locationManager = LocationManager()
    @State private var routeManager = RouteManager()
    @State private var safeDestinationName: String = "Finding Safe Place ..."
    @State private var safeDestinationCoordinate: CLLocationCoordinate2D?
    @State private var lastRouteFetchLocation: CLLocation? = nil
    @State private var lastRouteFetchTime: Date = .distantPast
    @State private var showArriveConfirmation: Bool = false
    @Binding var showDirection: Bool
    
    var body: some View {
        Map(position: $locationManager.camera){
            if let safeDest = safeDestinationCoordinate {
                Annotation(safeDestinationName, coordinate: safeDest, anchor: .bottom) {
                    VStack(spacing: 0) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .red)
                        Image(systemName: "triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .rotationEffect(.degrees(180))
                            .offset(y: -4)
                    }
                }
            }
            
            UserAnnotation()
            
            if let route = routeManager.routeFriendToDestination {
                MapPolyline(route.polyline).stroke(Color.blue,
                    lineWidth: 5
                )
            }
            
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
        .task {
            // Active user: find safe place and draw route
            if let coord = locationManager.coordinate {
                WatchConnector.shared.sendStartSession(with: coord)
                await fetchRoute(from: coord)
            }
        }
        .onChange(of: locationManager.coordinate) { _, newCoord in
            guard let newCoord else { return }
            handleLocationChange(newCoord)
        }
        .navigationBarBackButtonHidden()
        .toolbar{
            ToolbarItem(placement: .cancellationAction){
                Button{
                    
                }label: {
                    Image(systemName: "xmark")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing){
                Button{
                    
                }label:{
                    Text("SOS").font(.system(size: 10, weight: .semibold));
                }
                .tint(Color.red)
                
            }
            
        }
        .overlay(alignment: .top){
            VStack{
                Text("ETA 22.00").foregroundColor(Color.blue)
            }.padding(35)
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottomLeading){
            let _ = print("currentStep is nil?: \(routeManager.currentStep == nil), routeFriendToDestination is nil?: \(routeManager.routeFriendToDestination == nil), currentStepIndex: \(routeManager.currentStepIndex)")
                
            if let step = routeManager.currentStep {
                let _ = print("Instruksi: \(step.instructions), Distance: \(step.distance)")
                HStack(spacing: 5){
                    Image(systemName: iconName(for: step.instructions)).font(.system(size: 25, weight: .bold))
                    VStack(alignment: .leading){
                        Text("\(Int(step.distance))m").font(.headline)
                        Text("\(instructionDestination(for: step.instructions))").font(.footnote)
                    }
                }
                .offset(x: 15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [Color.clear, Color.black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                )
            }
        }
        .overlay(alignment: .bottomTrailing) {
            BottomFloatingToolBar().padding(.trailing, 15)
        }
        .navigationDestination(isPresented: $showArriveConfirmation){
            ArriveConfirmationView(showDirection: $showDirection, showArriveConfirmation: $showArriveConfirmation).navigationBarBackButtonHidden()
        }
    }
    
    private func fetchRoute(from myCoordinate: CLLocationCoordinate2D) async {
        if safeDestinationCoordinate == nil {
            if let safePlace = await findNearestSafePlace(near: myCoordinate) {
                let placeName = safePlace.name ?? "Safe Place"
                safeDestinationName = placeName
                safeDestinationCoordinate = safePlace.location.coordinate
                routeManager.safePlaceName = placeName
                routeManager.safePlaceAddress = "Nearby Secure Zone"
//               liveTrackingManager?.updateDestination(name: placeName, coordinate: safePlace.location.coordinate)
                WatchConnector.shared.sendUpdateDestination(name: placeName, coordinate: safePlace.location.coordinate)
                print("✅ Found safe place: \(placeName) synced to RouteManager + Firestore")
            } else {
                let warningMessage = "No safe places nearby. Stay alert."
                safeDestinationName = warningMessage
                safeDestinationCoordinate = nil
                routeManager.safePlaceName = warningMessage
                routeManager.safePlaceAddress = "Move towards a main road"
            }
        }
        
        if let destCoord = safeDestinationCoordinate {
            print("Mau hitung rute dari \(myCoordinate) ke \(destCoord)")
            let calculatedRoute = await routeManager.getRoute(from: myCoordinate, to: destCoord)
            print("Hasil rute: \(calculatedRoute == nil ? "GAGAL/nil" : "BERHASIL")")
            routeManager.routeFriendToDestination = calculatedRoute
        } else {
            routeManager.routeFriendToDestination = nil
        }
    }
    
    // MARK: - Apple Maps Local Search (Progressive Expansion)
    private func findNearestSafePlace(near coordinate: CLLocationCoordinate2D) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .gasStation, .police, .hospital, .pharmacy, .foodMarket
        ])
        
        let searchRadii: [CLLocationDistance] = [1000, 3000, 5000]
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        for radius in searchRadii {
            request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: radius, longitudinalMeters: radius)
            let search = MKLocalSearch(request: request)
            do {
                let response = try await search.start()
                if !response.mapItems.isEmpty {
                    let sorted = response.mapItems.sorted {
                        $0.location.distance(from: userLocation) < $1.location.distance(from: userLocation)
                    }
                    print("✅ Found safe place within \(Int(radius)) meters!")
                    return sorted.first
                }
            } catch {
                print("⚠️ Nothing found within \(Int(radius)) meters, expanding search...")
            }
        }
        print("🚨 CRITICAL: Absolutely no safe places found within 5km.")
        return nil
    }
    
    private func handleLocationChange(_ newCoord: CLLocationCoordinate2D) {
//        liveTrackingManager?.uploadLocation(newCoord)
        routeManager.updateCurrentStep(location: newCoord)
        WatchConnector.shared.sendUploadLocation(with: newCoord)
        let newLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
        let timePassed = Date().timeIntervalSince(lastRouteFetchTime)
        guard timePassed >= 10.0 else { return }
        if let last = lastRouteFetchLocation {
            guard newLocation.distance(from: last) >= 15.0 else { return }
        }
        lastRouteFetchLocation = newLocation
        lastRouteFetchTime = Date()
        Task {
            await fetchRoute(from: newCoord)
        }
        
        if let destCoord = safeDestinationCoordinate{
            let destinationCLL = CLLocation(latitude: destCoord.latitude, longitude: destCoord.longitude)
            if destinationCLL.distance(from: newLocation) < 20 {
                showArriveConfirmation = true
            }
        }
    }
    
    private func iconName(for instructions: String) -> String{
        let lowercased = instructions.lowercased()
        
        if lowercased.contains("slight right"){
            return "arrow.up.right"
        }else if lowercased.contains("slight left"){
            return "arrow.up.left"
        }else if lowercased.contains("right"){
            return "arrow.turn.up.right"
        }else if lowercased.contains("left"){
            return "arrow.turn.up.left"
        }else if lowercased.contains("arrived") || lowercased.contains("destinations"){
            return "flag.fill"
        }else{
            return "arrow.up"
        }
    }
    
    private func instructionDestination(for instructions: String) -> String{
        let lowercased = instructions.lowercased()
        
        if lowercased.contains("slight right"){
            return "Turn Slightly Right"
        }else if lowercased.contains("slight left"){
            return "Turn Slightly Left"
        }else if lowercased.contains("right"){
            return "Turn Right"
        }else if lowercased.contains("left"){
            return "Turn Left"
        }else if lowercased.contains("arrived") || lowercased.contains("destinations"){
            return "You've arrived to the destination"
        }else{
            return "Keep Straight"
        }
    }
    
    @ViewBuilder
    func BottomFloatingToolBar() -> some View {
        VStack(spacing: 15){
            Image(systemName: "location.north.line.fill").rotationEffect(.degrees(-locationManager.heading))
            
            Button {
                withAnimation {
                    let target = locationManager.coordinate
                    let locationHeading = locationManager.heading
                    if let coord = target {
                        locationManager.camera = .camera(
                            MapCamera(
                                centerCoordinate: coord,
                                distance: 300,
                                heading: locationHeading,
                                pitch: 60
                            )
                        )
                    }
                }
            } label: {
                Image(systemName: "location.fill")
                    .frame(width: 15, height: 15)
                    .tint(.white)
            }.frame(width: 35, height: 35)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .offset(y: -20)
        .tint(.ungu)
    }
}

#Preview {
    @State var showDirection: Bool = true
    DirectionView(showDirection: $showDirection)
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
