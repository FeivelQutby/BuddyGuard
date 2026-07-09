//
//  ContentView.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 26/06/26.
//

import SwiftUI
import MapKit
import SwiftData
import FirebaseFirestore
import FirebaseAuth

struct MapView: View {
    
    let request: ActivityRequest?
    let role: MapRole
    
    /// Only used when role == .activeUser — broadcasts location/destination/status to Firestore
    var liveTrackingManager: LiveTrackingManager?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var locationManager = LocationManager()
    @State private var routeManager = RouteManager()
    @State private var myStatus: UserState = .OnTheWay
    
    @State private var showSheet: Bool = true
    @State private var sheetDetent: PresentationDetent = .height(80)
    @State private var sheetHeight: CGFloat = 0
    @State private var animationDuration: CGFloat = 0
    
    // MARK: - Safe Place + Tracked User State
    @State private var safeDestinationName: String = "Finding Safe Place..."
    @State private var safeDestinationCoordinate: CLLocationCoordinate2D?
    @State private var trackedUserCoordinate: CLLocationCoordinate2D?
    @State private var trackedUserStatus: UserState = .OnTheWay
    
    // Route throttling
    @State private var lastRouteFetchLocation: CLLocation? = nil
    @State private var lastRouteFetchTime: Date = .distantPast
    @State private var lastContactRouteFetchTime: Date = .distantPast
    
    // MARK: - Firestore listeners
    @State private var sessionListener: ListenerRegistration?
    
    // MARK: - Active user: friends watching them
    /// List of (contactUID, coordinate) of contacts currently watching the active user
    @State private var watchingContactCoordinates: [String: CLLocationCoordinate2D] = [:]
    @State private var friendsListener: ListenerRegistration?
    
    // MARK: - Emergency contact: "I'm on my way" navigation state
    @State private var contactNavigating: Bool = false

    // Active user: emergency contacts who can receive alerts
    @State private var notifiedContacts: [EmergencyContact] = []

    // Toasts
    @State private var showNotifiedToast = false
    @State private var showSOSToast = false
    @State private var showImSafeToast = false
    @State private var showContactOnWayToast = false
    
    init(request: ActivityRequest? = nil, role: MapRole = .emergencyContact, liveTrackingManager: LiveTrackingManager? = nil) {
        self.request = request
        self.role = role
        self.liveTrackingManager = liveTrackingManager
    }
    
    var body: some View {
        ZStack {
            Map(position: $locationManager.camera) {
                
                // MARK: - Tracked User Pin (Emergency Contact View)
                if role == .emergencyContact {
                    let coord = trackedUserCoordinate ?? request?.coordinate
                    if let coord {
                        Annotation(request?.name ?? "Friend", coordinate: coord, anchor: .bottom) {
                            ZStack {
                                Circle()
                                    .fill(trackedUserStatus == .Urgent ? Color.red : Color.blue)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "figure.wave")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                
                // MARK: - Safe Place Destination Pin
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
                
                // MARK: - Active user: show watching contacts' locations
                if role == .activeUser {
                    ForEach(Array(watchingContactCoordinates.keys), id: \.self) { uid in
                        if let coord = watchingContactCoordinates[uid] {
                            Annotation("Friend", coordinate: coord, anchor: .bottom) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "person.fill")
                                        .font(.callout)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                }
                
                // Current user's own pin
                UserAnnotation()
                
                // Route: contact → friend (emergency contact role)
                if role == .emergencyContact, let route = routeManager.routeToFriend {
                    MapPolyline(route.polyline).stroke(Color.blue, lineWidth: 5)
                }
                
                // Route: friend → destination (either role)
                if let route = routeManager.routeFriendToDestination {
                    MapPolyline(route.polyline).stroke(
                        role == .emergencyContact ? Color.orange : Color.blue,
                        lineWidth: 5
                    )
                }
            }
            .onAppear {
                locationManager.requestLocationPermission()
                setupRole()
                if role == .activeUser {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showNotifiedToast = true
                    }
                }
            }
            .onDisappear {
                cleanUp()
            }
            .task {
                // Active user: find safe place and draw route
                if role == .activeUser, let coord = locationManager.coordinate {
                    await fetchRoute(from: coord)
                }
            }
            .onChange(of: locationManager.coordinate) { _, newCoord in
                guard let newCoord else { return }
                handleLocationChange(newCoord)
            }
            .onChange(of: trackedUserCoordinate) { _, newCoord in
                // Re-center camera on the tracked friend whenever their pin moves
                if role == .emergencyContact, let newCoord {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        locationManager.camera = .region(
                            MKCoordinateRegion(
                                center: newCoord,
                                latitudinalMeters: 800,
                                longitudinalMeters: 800
                            )
                        )
                    }
                }
            }
            .sheet(isPresented: $showSheet) {
                BottomSheetCard(
                    request: request,
                    role: role,
                    sheetDetent: $sheetDetent,
                    routeManager: $routeManager,
                    trackedUserStatus: trackedUserStatus,
                    notifiedContacts: notifiedContacts,
                    onSOS: {
                        myStatus = .Urgent
                        liveTrackingManager?.updateStatus(.Urgent)
                        showSOSToast = true
                    },
                    onImSafe: {
                        myStatus = .Arrived
                        liveTrackingManager?.updateStatus(.Arrived)
                        showImSafeToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { dismiss() }
                    },
                    onImOnMyWay: {
                        handleImOnMyWay()
                    }
                )
                .presentationDetents([.height(80), .height(350)], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onGeometryChange(for: CGFloat.self) { max(min($0.size.height, 350), 0) } action: { _, newValue in
                    sheetHeight = newValue
                    let diff = abs(newValue - sheetHeight)
                    animationDuration = max(min(diff / 100, 0.3), 0)
                }
                .ignoresSafeArea()
                .interactiveDismissDisabled()
            }
            .overlay(alignment: .bottomTrailing) {
                BottomFloatingToolBar().padding(.trailing, 15)
            }
            
            // MARK: - Direction Card + Back Button
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    HStack(alignment: .top) {
                        if role == .emergencyContact {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.backward")
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.gray)
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            .controlSize(.large)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)

                    if let step = routeManager.currentStep(for: role) {
                        TopSheetCard(
                            step: step,
                            currentIndex: routeManager.currentStepIndex,
                            totalSteps: routeManager.stepsCount(for: role)
                        )
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 10)
                .animation(.easeInOut(duration: 0.3), value: routeManager.currentStepIndex)
            }

            // MARK: - Toasts
            .toast(isPresented: $showNotifiedToast, icon: "checkmark.circle.fill", message: "Emergency contacts have been notified", duration: 3.0)
            .toast(isPresented: $showSOSToast, icon: "exclamationmark.triangle.fill", message: "SOS alert sent to your contacts", tint: .red, duration: 3.0)
            .toast(isPresented: $showImSafeToast, icon: "hand.thumbsup.fill", message: "You're safe! Ending session...", duration: 2.0)
            .toast(isPresented: $showContactOnWayToast, icon: "figure.walk", message: "A contact is on the way!", tint: .green, duration: 3.0)
            .onChange(of: watchingContactCoordinates.count) { oldCount, newCount in
                if newCount > oldCount {
                    HapticManager.notification(.success)
                    showContactOnWayToast = true
                }
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupRole() {
        if role == .emergencyContact, let request, !request.sessionId.isEmpty {
            // Set initial tracked coordinate and camera
            let initialCoord = request.coordinate
            trackedUserCoordinate = initialCoord
            locationManager.camera = .region(
                MKCoordinateRegion(center: initialCoord, latitudinalMeters: 800, longitudinalMeters: 800)
            )
            
            // Initialize destination from request if already known
            if let destName = request.destinationName,
               let destLat = request.destinationLatitude,
               let destLng = request.destinationLongitude {
                safeDestinationName = destName
                safeDestinationCoordinate = CLLocationCoordinate2D(latitude: destLat, longitude: destLng)
                routeManager.safePlaceName = destName
                routeManager.safePlaceAddress = "Nearby Secure Zone"
            }
            
            startSessionListener(sessionId: request.sessionId)
        }
        
        if role == .activeUser {
            if let sessionId = liveTrackingManager?.sessionId {
                startFriendsOnWayListener(sessionId: sessionId)
            }
            Task { await loadNotifiedContacts() }
            if let coord = locationManager.coordinate {
                Task {
                    routeManager.sourcePlaceName = await routeManager.getSourcePlaceName(from: coord)
                }
            }
        }
    }
    
    private func cleanUp() {
        sessionListener?.remove()
        sessionListener = nil
        friendsListener?.remove()
        friendsListener = nil
        
        if role == .activeUser {
            liveTrackingManager?.stopSession()
        }
    }
    
    private func loadNotifiedContacts() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("users").document(uid)
                .collection("contacts")
                .whereField("canSendTo", isEqualTo: true)
                .getDocuments()
            var contacts: [EmergencyContact] = []
            for doc in snapshot.documents {
                let data = doc.data()
                contacts.append(EmergencyContact(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "?",
                    email: data["email"] as? String ?? "",
                    canSendTo: true,
                    canReceiveFrom: data["canReceiveFrom"] as? Bool ?? false
                ))
            }
            notifiedContacts = contacts
        } catch {
            print("⚠️ Failed to load notified contacts: \(error.localizedDescription)")
        }
    }

    // MARK: - Location Change Handler
    
    private func handleLocationChange(_ newCoord: CLLocationCoordinate2D) {
        routeManager.updateCurrentStep(location: newCoord, role: role)

        if role == .activeUser {
            liveTrackingManager?.uploadLocation(newCoord)
            
            let newLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
            let timePassed = Date().timeIntervalSince(lastRouteFetchTime)
            guard timePassed >= 10.0 else { return }
            if let last = lastRouteFetchLocation {
                guard newLocation.distance(from: last) >= 15.0 else { return }
            }
            lastRouteFetchLocation = newLocation
            lastRouteFetchTime = Date()
            Task { await fetchRoute(from: newCoord) }
        }
        
        if role == .emergencyContact {
            let newLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
            let timePassed = Date().timeIntervalSince(lastContactRouteFetchTime)
            guard timePassed >= 10.0 else { return }
            if let last = lastRouteFetchLocation {
                guard newLocation.distance(from: last) >= 15.0 else { return }
            }
            lastRouteFetchLocation = newLocation
            lastContactRouteFetchTime = Date()
            
            if contactNavigating, let destCoord = safeDestinationCoordinate {
                // Navigate contact → safe destination
                Task {
                    let route = await routeManager.getRoute(from: newCoord, to: destCoord)
                    routeManager.routeToFriend = route
                }
            } else if let trackedCoord = trackedUserCoordinate {
                // Show contact → friend route
                Task {
                    let route = await routeManager.getRoute(from: newCoord, to: trackedCoord)
                    routeManager.routeToFriend = route
                }
            }
        }
    }
    
    // MARK: - "I'm On My Way" Handler
    
    /// Best practice: navigate the contact to the **safe destination** (not the friend's
    /// live location, which keeps moving). This also writes a Firestore flag so the active
    /// user can see their contact is on the way and the contact's location appears on their map.
    private func handleImOnMyWay() {
        guard let sessionId = request?.sessionId, !sessionId.isEmpty else { return }
        guard let destCoord = safeDestinationCoordinate else { return }
        guard let myCoord = locationManager.coordinate else { return }
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        
        contactNavigating = true
        
        // 1. Draw route from contact → safe destination
        Task {
            let route = await routeManager.getRoute(from: myCoord, to: destCoord)
            routeManager.routeToFriend = route
        }
        
        // 2. Write to Firestore so active user can see the contact coming
        let db = Firestore.firestore()
        let contactData: [String: Any] = [
            "contactUID": myUID,
            "latitude": myCoord.latitude,
            "longitude": myCoord.longitude,
            "onWay": true,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("tracking_sessions").document(sessionId)
            .collection("contacts_on_way").document(myUID)
            .setData(contactData) { error in
                if let error = error {
                    print("⚠️ Failed to write contactOnWay: \(error.localizedDescription)")
                } else {
                    print("✅ Contact marked as on the way to safe destination")
                }
            }
        
        // 3. Keep contact location updated while navigating
        startContactLocationUpdater(sessionId: sessionId, myUID: myUID)
    }
    
    /// Periodically uploads the contact's own location to the session while they are navigating.
    private func startContactLocationUpdater(sessionId: String, myUID: String) {
        // The contact's location is already tracked via locationManager.coordinate changes,
        // so we piggyback on onChange(of: locationManager.coordinate) above.
        // This flag ensures those changes write to Firestore.
        contactNavigating = true
    }
    
    // MARK: - Firestore: Listen for Friends on Way (Active User Role)
    
    private func startFriendsOnWayListener(sessionId: String) {
        friendsListener?.remove()
        let db = Firestore.firestore()
        friendsListener = db.collection("tracking_sessions").document(sessionId)
            .collection("contacts_on_way")
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                var coords: [String: CLLocationCoordinate2D] = [:]
                for doc in docs {
                    let data = doc.data()
                    if data["onWay"] as? Bool == true,
                       let lat = data["latitude"] as? Double,
                       let lng = data["longitude"] as? Double {
                        coords[doc.documentID] = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    }
                }
                watchingContactCoordinates = coords
            }
    }
    
    // Also update contact location in Firestore when navigating
    private func updateContactLocationIfNavigating(_ coord: CLLocationCoordinate2D) {
        guard contactNavigating,
              let sessionId = request?.sessionId, !sessionId.isEmpty,
              let myUID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let updateData: [String: Any] = [
            "latitude": coord.latitude,
            "longitude": coord.longitude,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("tracking_sessions").document(sessionId)
            .collection("contacts_on_way").document(myUID)
            .updateData(updateData)
    }
    
    // MARK: - Firestore Session Listener (Emergency Contact Role)
    
    private func startSessionListener(sessionId: String) {
        sessionListener?.remove()
        let db = Firestore.firestore()
        sessionListener = db.collection("tracking_sessions").document(sessionId)
            .addSnapshotListener { [self] snapshot, error in
                guard let data = snapshot?.data() else { return }
                
                let lat = data["latitude"] as? Double ?? 0.0
                let lng = data["longitude"] as? Double ?? 0.0
                let newTrackedCoord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                trackedUserCoordinate = newTrackedCoord
                
                let statusRaw = data["status"] as? String ?? "OnTheWay"
                trackedUserStatus = UserState(rawValue: statusRaw) ?? .OnTheWay
                
                if let destName = data["destinationName"] as? String,
                   let destLat = data["destinationLatitude"] as? Double,
                   let destLng = data["destinationLongitude"] as? Double {
                    safeDestinationName = destName
                    let destCoord = CLLocationCoordinate2D(latitude: destLat, longitude: destLng)
                    safeDestinationCoordinate = destCoord
                    routeManager.safePlaceName = destName
                    routeManager.safePlaceAddress = "Nearby Secure Zone"
                    
                    // Route: friend → destination (orange line)
                    Task {
                        let route = await routeManager.getRoute(from: newTrackedCoord, to: destCoord)
                        routeManager.routeFriendToDestination = route
                    }
                }
                
                // Route: contact → friend or destination (blue line)
                if let myCoord = locationManager.coordinate {
                    let target = contactNavigating ? safeDestinationCoordinate ?? newTrackedCoord : newTrackedCoord
                    Task {
                        let route = await routeManager.getRoute(from: myCoord, to: target)
                        routeManager.routeToFriend = route
                    }
                }
                
                // Update contact location in Firestore if navigating
                if let myCoord = locationManager.coordinate {
                    updateContactLocationIfNavigating(myCoord)
                }
                
                let isActive = data["isActive"] as? Bool ?? true
                if !isActive {
                    print("✅ MapView: Tracked user has ended their session.")
                }
            }
    }
    
    // MARK: - Route Logic (Active User Only)
    private func fetchRoute(from myCoordinate: CLLocationCoordinate2D) async {
        if safeDestinationCoordinate == nil {
            if let safePlace = await findNearestSafePlace(near: myCoordinate) {
                let placeName = safePlace.name ?? "Safe Place"
                safeDestinationName = placeName
                safeDestinationCoordinate = safePlace.location.coordinate
                routeManager.safePlaceName = placeName
                routeManager.safePlaceAddress = "Nearby Secure Zone"
                liveTrackingManager?.updateDestination(name: placeName, coordinate: safePlace.location.coordinate)
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
            let calculatedRoute = await routeManager.getRoute(from: myCoordinate, to: destCoord)
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
    
    // MARK: - Floating Button
    @ViewBuilder
    func BottomFloatingToolBar() -> some View {
        Button {
            withAnimation {
                let target = role == .emergencyContact
                    ? (trackedUserCoordinate ?? locationManager.coordinate)
                    : locationManager.coordinate
                if let coord = target {
                    locationManager.camera = .region(
                        MKCoordinateRegion(center: coord, latitudinalMeters: 800, longitudinalMeters: 800)
                    )
                }
            }
        } label: {
            Image(systemName: role == .emergencyContact ? "figure.wave" : "location.fill")
                .frame(width: 20, height: 20)
                .tint(.white)
        }
        .font(.title3)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .offset(y: -sheetHeight)
        .animation(.interpolatingSpring(duration: animationDuration, bounce: 0, initialVelocity: 0), value: sheetHeight)
        .tint(.normalActiveNd)
    }
}

#Preview("Emergency Contact") {
    MapView(request: ActivityViewModel.sampleRequests[0], role: .emergencyContact)
}

#Preview("Emergency Contact Dark") {
    MapView(request: ActivityViewModel.sampleRequests[0], role: .emergencyContact)
        .preferredColorScheme(.dark)
}

#Preview("Active User") {
    MapView(role: .activeUser)
}

#Preview("Active User Dark") {
    MapView(role: .activeUser)
        .preferredColorScheme(.dark)
}

extension CLLocation {
    static let source = CLLocation(latitude: DummyData.user1.coordinate.latitude, longitude: DummyData.user1.coordinate.longitude)
    static let destination = CLLocation(latitude: DummyData.safeZone.safeAddress.latitude, longitude: DummyData.safeZone.safeAddress.longitude)
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
