//
//  ContentView.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 26/06/26.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View{
    
    let sourcePlacemark = MKMapItem(location: .source, address: nil)
    let destination = MKMapItem(location: .destination, address: nil)
    
    @State private var locationManager = LocationManager()
    @State private var routeManager = RouteManager()
    
    @State private var showSheet: Bool = true
    @State private var sheetDetent: PresentationDetent = .height(80)
    @State private var sheetHeight: CGFloat = 0
    @State private var animationDuration: CGFloat = 0
    
    var body: some View{
        ZStack{
            Map(position: $locationManager.camera){
                Annotation("\(DummyData.user1.nama)", coordinate: DummyData.user1.coordinate, anchor: .bottom){
                    Circle().fill(Color.blue)
                }
                
                Annotation("Safe Place", coordinate: DummyData.safeZone.safeAddress, anchor: .bottom){
                    Image(systemName: "mappin").foregroundStyle(.red)
                }
                
                UserAnnotation()
                
                if let route = routeManager.routeToFriend{
                    MapPolyline(route.polyline).stroke(Color.blue, lineWidth: 5)
                }
                
                if let route = routeManager.routeFriendToDestination{
                    MapPolyline(route.polyline).stroke(Color.blue, lineWidth: 5)
                }
            }
            .onAppear{
                locationManager.manager.requestWhenInUseAuthorization()
            }
            .task{
                routeManager.routeFriendToDestination = await routeManager.getRoute(from: DummyData.user1.coordinate, to: DummyData.safeZone.safeAddress)
                routeManager.routeToFriend = await routeManager.getRoute(from: locationManager.coordinate, to: DummyData.user1.coordinate)
            }
            .onChange(of: locationManager.coordinate){ oldValue, newValue in
                Task{
                    routeManager.routeToFriend = await routeManager.getRoute(from: newValue, to: DummyData.user1.coordinate)
                }
            }
            .sheet(isPresented: $showSheet){
                BottomSheetView(sheetDetent: $sheetDetent, routeManager: $routeManager).presentationDetents([.height(80), .height(350)], selection: $sheetDetent)
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
                    Button(action: {}) {
                        Image(systemName: "chevron.backward").frame(width: 20, height: 20)
                    }.buttonStyle(.glass).buttonBorderShape(.circle).controlSize(.large)
                    Spacer()
                    Button(action: {}) {
                        Text("SOS").foregroundStyle(.white).font(.body).fontWeight(.bold).frame(width: 40, height: 20)
                    }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).tint(Color.red).controlSize(.large)
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

#Preview {
    MapView()
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

