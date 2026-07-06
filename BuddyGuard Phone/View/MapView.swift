//
//  ContentView.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 26/06/26.
//

import SwiftUI
import MapKit
import SwiftData

/// Who is looking at this map right now — determines which pin/route is relevant.
/// This is a *presentation* concept (decided by whoever presents MapView), not a
/// property of ActivityRequest/UserLocation, since the same request data can be
/// viewed from either side.
enum MapRole {
    /// Someone watching a friend's live location (opened from ActivityView).
    case emergencyContact
    /// The at-risk person viewing their own route to the safe zone.
    case activeUser
}

struct MapView: View{
    
    let request: ActivityRequest?
    let role: MapRole
    
    let sourcePlacemark = MKMapItem(location: .source, address: nil)
    let destination = MKMapItem(location: .destination, address: nil)
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var locationManager = LocationManager()
    @State private var routeManager = RouteManager()
    @State private var myStatus: UserState = .OnTheWay
    
    @State private var showSheet: Bool = true
    @State private var sheetDetent: PresentationDetent = .height(80)
    @State private var sheetHeight: CGFloat = 0
    @State private var animationDuration: CGFloat = 0
    
    init(request: ActivityRequest? = nil, role: MapRole = .emergencyContact) {
        self.request = request
        self.role = role
    }
    
    var body: some View{
        ZStack{
            Map(position: $locationManager.camera){
                if role == .emergencyContact, let request {
                    Annotation("\(request.name)", coordinate: request.coordinate, anchor: .bottom){
                        Circle().fill(Color.blue)
                    }
                }
                
                Annotation("Safe Place", coordinate: DummyData.safeZone.safeAddress, anchor: .bottom){
                    Image(systemName: "mappin").foregroundStyle(.red)
                }
                
                UserAnnotation()
                
                if role == .emergencyContact, let route = routeManager.routeToFriend{
                    MapPolyline(route.polyline).stroke(Color.blue, lineWidth: 5)
                }
                
                if role == .activeUser, let route = routeManager.routeFriendToDestination{
                    MapPolyline(route.polyline).stroke(Color.blue, lineWidth: 5)
                }
            }
            .onAppear{
                locationManager.manager.requestWhenInUseAuthorization()
            }
            .task{
                await fetchRoute(from: locationManager.coordinate)
            }
            .onChange(of: locationManager.coordinate){ oldValue, newValue in
                Task{
                    await fetchRoute(from: newValue)
                }
            }
            .sheet(isPresented: $showSheet){
                BottomSheetView(
                    request: request,
                    role: role,
                    sheetDetent: $sheetDetent,
                    routeManager: $routeManager,
                    onSOS: { myStatus = .Urgent /* TODO: send to backend once notif layer exists */ },
                    onImSafe: { myStatus = .Arrived /* TODO: send to backend once notif layer exists */ }
                ).presentationDetents([.height(80), .height(350)], selection: $sheetDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onGeometryChange(for: CGFloat.self){
                        max(min($0.size.height, 350),0)
                    }action: { oldValue, newValue in
                        sheetHeight = newValue
                        
                        //Calculating Animation Duration
                        let diff = abs(newValue - oldValue)
                        let duration = max(min(diff / 100, 0.3), 0)
                        animationDuration = duration
                    }
                    .ignoresSafeArea()
                    .interactiveDismissDisabled()
                    .preferredColorScheme(.dark)
    
            }
            .overlay(alignment: .bottomTrailing){
                BottomFloatinToolBar().padding(.trailing, 15)
            }
            
            VStack{
                HStack(alignment: .top){
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.backward").frame(width: 20, height: 20)
                    }.buttonStyle(.glass).buttonBorderShape(.circle).controlSize(.large)
                    Spacer()
                }.padding(10)
                    .overlay(alignment: .center){
                    VStack(){
                        Text("Live Tracking").font(.system(size: 15, weight: .semibold))
                        Text("Started at \(Date(), format: .dateTime.hour().minute())").foregroundColor(Color(red: 114/255, green: 114/255, blue: 114/255))
                    }
                }
                Spacer()
            }
        }
    }
    
    private func fetchRoute(from myCoordinate: CLLocationCoordinate2D) async {
        switch role {
        case .emergencyContact:
            guard let request else { return }
            // I'm watching request.name — route line I need on the map is me -> them.
            routeManager.routeToFriend = await routeManager.getRoute(from: myCoordinate, to: request.coordinate)
            // Still fetch this (not drawn) — the bottom sheet's ETA/distance text reads from it.
            routeManager.routeFriendToDestination = await routeManager.getRoute(from: request.coordinate, to: DummyData.safeZone.safeAddress)
        case .activeUser:
            // I am the one heading to safety — route line I need on the map is me -> safe zone.
            routeManager.routeFriendToDestination = await routeManager.getRoute(from: myCoordinate, to: DummyData.safeZone.safeAddress)
        }
    }
    
    @ViewBuilder
    func BottomFloatinToolBar() -> some View{
        Button{
            withAnimation{
                locationManager.camera = .region(MKCoordinateRegion(center: locationManager.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))
            }
        }label:{
            Image(systemName: "location.fill").frame(width: 20, height: 20).tint(.white)
        }
        .font(.title3)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .offset(y: -sheetHeight)
        .animation(.interpolatingSpring(duration: animationDuration, bounce: 0, initialVelocity: 0), value: sheetHeight)
        .tint(Color.normalActive)
    }
}

#Preview("Emergency Contact") {
    MapView(request: ActivityViewModel.sampleRequests[0], role: .emergencyContact)
}

#Preview("Active User") {
    MapView(role: .activeUser)
}

extension CLLocation{
    static let source = CLLocation(latitude: DummyData.user1.coordinate.latitude, longitude: DummyData.user1.coordinate.longitude)
    
    static let destination = CLLocation(latitude: DummyData.safeZone.safeAddress.latitude, longitude: DummyData.safeZone.safeAddress.longitude)
}

extension CLLocationCoordinate2D: @retroactive Equatable{
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool{
        lhs.latitude == rhs.latitude && lhs.latitude == rhs.longitude
    }
}
