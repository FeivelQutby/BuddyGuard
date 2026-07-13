//
//  LiveTrackingManager.swift
//  BuddyGuard
//
//  Created by BuddyGuard Team on 06/07/26.
//

import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth
import ActivityKit

@Observable
class LiveTrackingManager {
    
    // MARK: - Public State
    var sessionId: String?
    var isActive: Bool = false

    // MARK: - Private
    private let db = Firestore.firestore()
    private var lastUploadTime: Date = .distantPast
    private var lastUploadedLocation: CLLocation?

    // MARK: - Live Activity
    private var liveActivity: Activity<EmergencyActivityAttributes>?
    
    // Throttle: minimum 5 seconds between writes
    private let minimumUploadInterval: TimeInterval = 5.0
    // Throttle: minimum 10 meters of movement before writing
    private let minimumDistanceChange: CLLocationDistance = 10.0
    
    // MARK: - Start a New Tracking Session
    
    /// Creates a new tracking session document in Firestore and marks it active.
    /// Called once when the user triggers emergency mode (3s hold).
    func startSession(coordinate: CLLocationCoordinate2D) {
        guard let currentUser = Auth.auth().currentUser else {
            print("🚨 LiveTrackingManager: No authenticated user, cannot start session.")
            return
        }

        let newSessionId = UUID().uuidString
        self.sessionId = newSessionId
        self.isActive = true
        self.lastUploadTime = Date()
        self.lastUploadedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        startLiveActivity(userName: currentUser.displayName ?? "User", sessionId: newSessionId)
        
        let sessionData: [String: Any] = [
            "sessionId": newSessionId,
            "userId": currentUser.uid,
            "userName": currentUser.displayName ?? "Unknown User",
            "status": UserState.OnTheWay.rawValue,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "destinationName": NSNull(),
            "destinationLatitude": NSNull(),
            "destinationLongitude": NSNull(),
            "startedAt": FieldValue.serverTimestamp(),
            "lastUpdated": FieldValue.serverTimestamp(),
            "isActive": true
        ]
        
        db.collection("tracking_sessions").document(newSessionId).setData(sessionData) { error in
            if let error = error {
                print("🚨 LiveTrackingManager: Failed to create session — \(error.localizedDescription)")
            } else {
                print("✅ LiveTrackingManager: Session \(newSessionId) created successfully.")
            }
        }
    }
    
    // MARK: - Continuous Location Updates (Throttled)
    
    /// Called whenever the user's location changes. Applies time + distance throttling
    /// to avoid excessive Firestore writes.
    func uploadLocation(_ coordinate: CLLocationCoordinate2D) {
        guard isActive, let sessionId = sessionId else { return }
        
        let now = Date()
        let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Time guard: at least 5 seconds since last upload
        let timeSinceLastUpload = now.timeIntervalSince(lastUploadTime)
        guard timeSinceLastUpload >= minimumUploadInterval else { return }
        
        // Distance guard: at least 10 meters of movement
        if let lastLocation = lastUploadedLocation {
            let distanceMoved = newLocation.distance(from: lastLocation)
            guard distanceMoved >= minimumDistanceChange else { return }
        }
        
        // Guards passed — write to Firestore
        lastUploadTime = now
        lastUploadedLocation = newLocation
        
        let updateData: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection("tracking_sessions").document(sessionId).updateData(updateData) { error in
            if let error = error {
                print("⚠️ LiveTrackingManager: Location upload failed — \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Update Destination Info
    
    /// Called once after `findNearestSafePlace()` resolves in MapView.
    func updateDestination(name: String, coordinate: CLLocationCoordinate2D) {
        guard let sessionId = sessionId else { return }
        
        let updateData: [String: Any] = [
            "destinationName": name,
            "destinationLatitude": coordinate.latitude,
            "destinationLongitude": coordinate.longitude,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection("tracking_sessions").document(sessionId).updateData(updateData) { error in
            if let error = error {
                print("⚠️ LiveTrackingManager: Destination update failed — \(error.localizedDescription)")
            } else {
                print("✅ LiveTrackingManager: Destination synced — \(name)")
            }
        }
    }
    
    // MARK: - Update Status
    
    /// Called when the user taps SOS or "I'm Safe".
    func updateStatus(_ status: UserState) {
        guard let sessionId = sessionId else { return }
        
        var updateData: [String: Any] = [
            "status": status.rawValue,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        // If the user marks themselves safe, end the session
        if status == .Arrived {
            updateData["isActive"] = false
        }
        
        db.collection("tracking_sessions").document(sessionId).updateData(updateData) { error in
            if let error = error {
                print("⚠️ LiveTrackingManager: Status update failed — \(error.localizedDescription)")
            } else {
                print("✅ LiveTrackingManager: Status updated to \(status.rawValue)")
            }
        }
        
        if status == .Arrived {
            endLiveActivity()
            isActive = false
        }
    }
    
    // MARK: - End Session
    
    /// Marks the session as inactive in Firestore. Called on map dismiss.
    func stopSession() {
        guard let sessionId = sessionId else { return }

        let updateData: [String: Any] = [
            "isActive": false,
            "lastUpdated": FieldValue.serverTimestamp()
        ]

        db.collection("tracking_sessions").document(sessionId).updateData(updateData) { error in
            if let error = error {
                print("⚠️ LiveTrackingManager: Stop session failed — \(error.localizedDescription)")
            } else {
                print("✅ LiveTrackingManager: Session ended.")
            }
        }

        endLiveActivity()
        isActive = false
        self.sessionId = nil
    }
    
    func triggerEmergencyAlert(
        alertId: String,
        senderName: String,
        friendTokens: [String],
        notificationType: String = "emergency_start"
    ) {
        // 1. Your Cloudflare Worker URL
        guard let url = URL(string: "https://buddyguard-push-notif.george-maximillian.workers.dev/") else { return }
        
        // 2. Prepare the HTTP POST Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 3. Package the data Cloudflare needs (including notification type)
        let body: [String: Any] = [
            "notificationType": notificationType,
            "senderId": Auth.auth().currentUser?.uid ?? "Unknown",
            "alertId": alertId,
            "senderName": senderName,
            "friendTokens": friendTokens
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to encode JSON: \(error)")
            return
        }
        
        // 4. Fire the request to Cloudflare
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("🚨 Failed to trigger Worker: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Emergency triggered successfully! [type: \(notificationType)]")
            } else if let data = data, let body = String(data: data, encoding: .utf8) {
                print("⚠️ Worker returned an error: \(body)")
            }
        }.resume()
    }

    // MARK: - Live Activity

    private func startLiveActivity(userName: String, sessionId: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("ℹ️ Live Activities not enabled.")
            return
        }

        let attributes = EmergencyActivityAttributes(
            userName: userName,
            sessionId: sessionId,
            startTime: Date()
        )
        let initialState = EmergencyActivityAttributes.ContentState(
            status: "active",
            contactsNotified: 0
        )

        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            print("✅ Live Activity started.")
        } catch {
            print("⚠️ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    func updateLiveActivityContacts(_ count: Int) {
        guard let activity = liveActivity else { return }
        let state = EmergencyActivityAttributes.ContentState(
            status: "active",
            contactsNotified: count
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        let finalState = EmergencyActivityAttributes.ContentState(
            status: "ended",
            contactsNotified: 0
        )
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            print("✅ Live Activity ended.")
        }
        liveActivity = nil
    }
}

