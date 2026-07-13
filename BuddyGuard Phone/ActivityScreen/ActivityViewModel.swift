//
//  ActivityViewModel.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import CoreLocation
import Foundation
import Observation
import FirebaseFirestore
import FirebaseAuth
import ActivityKit

@Observable
final class ActivityViewModel {
    var requests: [ActivityRequest]
    var activeRequest: ActivityRequest?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var contactUIDs: [String] = []
    private var contactActivities: [String: Activity<EmergencyActivityAttributes>] = [:]

    init(requests: [ActivityRequest] = []) {
        self.requests = requests
        
        // Only start listening if we have an authenticated user
        if Auth.auth().currentUser != nil {
            Task {
                await loadContactsAndStartListening()
            }
        }
    }
    
    deinit {
        listener?.remove()
    }

    func startTracking(_ request: ActivityRequest) {
        activeRequest = request
    }
    
    // MARK: - Load Contacts Then Listen
    
    /// First fetches the current user's emergency contact UIDs (those who can send alerts to them),
    /// then starts listening for active tracking sessions from those contacts only.
    private func loadContactsAndStartListening() async {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Fetch contacts where canReceiveFrom == true
            // (meaning the current user can RECEIVE alerts FROM these contacts)
            let snapshot = try await db.collection("users").document(currentUID)
                .collection("contacts")
                .whereField("canReceiveFrom", isEqualTo: true)
                .getDocuments()
            
            contactUIDs = snapshot.documents.map { $0.documentID }
            
            // Now start the live listener
            await MainActor.run {
                startListeningForActiveSessions()
            }
        } catch {
            print("⚠️ ActivityViewModel: Failed to load contacts — \(error.localizedDescription)")
            // Fall back to listening to all sessions if contacts can't be loaded
            startListeningForActiveSessions()
        }
    }
    
    // MARK: - Live Session Listener
    
    private func startListeningForActiveSessions() {
        listener?.remove()
        
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        // Listen for active tracking sessions
        listener = db.collection("tracking_sessions")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self, let documents = querySnapshot?.documents else {
                    print("Error pulling live sessions: \(error?.localizedDescription ?? "")")
                    return
                }
                
                var activeSessions: [ActivityRequest] = []
                
                for doc in documents {
                    let data = doc.data()
                    let userId = data["userId"] as? String ?? ""
                    
                    // Skip own sessions — don't show your own tracking in Activity
                    if userId == currentUID { continue }
                    
                    // Filter: only show sessions from emergency contacts
                    if !self.contactUIDs.isEmpty && !self.contactUIDs.contains(userId) {
                        continue
                    }
                    
                    let userName = data["userName"] as? String ?? "Unknown User"
                    let lat = data["latitude"] as? Double ?? 0.0
                    let lng = data["longitude"] as? Double ?? 0.0
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    
                    let sessionId = data["sessionId"] as? String ?? doc.documentID
                    let destName = data["destinationName"] as? String
                    let destLat = data["destinationLatitude"] as? Double
                    let destLng = data["destinationLongitude"] as? Double
                    
                    // Parse status
                    let statusRaw = data["status"] as? String ?? "OnTheWay"
                    let state = UserState(rawValue: statusRaw) ?? .OnTheWay
                    
                    // Format timestamp
                    let dbTimestamp = (data["startedAt"] as? Timestamp)?.dateValue() ?? Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h.mm a"
                    let startedAtString = "Started at \(formatter.string(from: dbTimestamp))"
                    
                    // Build route description
                    let routeText = destName != nil
                        ? "Live Location → \(destName!)"
                        : "Live Location → Finding safe place..."
                    
                    let request = ActivityRequest(
                        id: UUID(),
                        name: userName,
                        startedAt: startedAtString,
                        route: routeText,
                        eta: "Live",
                        distance: "—",
                        coordinate: coord,
                        state: state,
                        sessionId: sessionId,
                        userId: userId,
                        destinationName: destName,
                        destinationLatitude: destLat,
                        destinationLongitude: destLng
                    )
                    
                    activeSessions.append(request)
                }
                
                DispatchQueue.main.async {
                    self.requests = activeSessions
                    self.syncLiveActivities(activeSessions)
                }
            }
    }

    /// Re-fetch contacts and re-start listening. Useful after accepting a new invitation.
    func refreshContacts() {
        Task {
            await loadContactsAndStartListening()
        }
    }

    // MARK: - Live Activities for Emergency Contacts

    private func syncLiveActivities(_ sessions: [ActivityRequest]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let activeSessionIds = Set(sessions.map { $0.sessionId })

        for session in sessions {
            if contactActivities[session.sessionId] == nil {
                startContactLiveActivity(for: session)
            } else {
                updateContactLiveActivity(for: session)
            }
        }

        for (sessionId, activity) in contactActivities where !activeSessionIds.contains(sessionId) {
            let finalState = EmergencyActivityAttributes.ContentState(
                status: "Arrived",
                contactsNotified: 0
            )
            Task {
                await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            }
            contactActivities.removeValue(forKey: sessionId)
        }
    }

    private func startContactLiveActivity(for request: ActivityRequest) {
        let attributes = EmergencyActivityAttributes(
            userName: request.name,
            sessionId: request.sessionId,
            startTime: Date(),
            role: "emergencyContact"
        )
        let state = EmergencyActivityAttributes.ContentState(
            status: request.state.rawValue,
            contactsNotified: 0
        )
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            contactActivities[request.sessionId] = activity
        } catch {
            print("⚠️ Failed to start contact Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateContactLiveActivity(for request: ActivityRequest) {
        guard let activity = contactActivities[request.sessionId] else { return }
        let state = EmergencyActivityAttributes.ContentState(
            status: request.state.rawValue,
            contactsNotified: 0
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }
}

extension ActivityViewModel {
    static let sampleRequests = [
        ActivityRequest(
            name: "Maya",
            startedAt: "Started at 10.00 PM",
            route: "GOP 9 → Indomaret Foresta",
            eta: "22.10",
            distance: "1,2 km",
            coordinate: CLLocationCoordinate2D(latitude: -6.3024, longitude: 106.6527),
            state: .OnTheWay,
            sessionId: "sample-session-1"
        ),
        ActivityRequest(
            name: "Clarice",
            startedAt: "Started at 9.50 PM",
            route: "Ice Business → Alfamart Ice",
            eta: "22.00",
            distance: "1,2 km",
            coordinate: CLLocationCoordinate2D(latitude: -6.3024, longitude: 106.6527),
            state: .Urgent,
            sessionId: "sample-session-2"
        )
    ]
}
