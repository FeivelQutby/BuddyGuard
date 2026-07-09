//
//  ActivityRequest.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import CoreLocation
import Foundation

struct ActivityRequest: Identifiable {
    let id: UUID
    let name: String
    let startedAt: String
    let route: String
    let eta: String
    let distance: String
    let coordinate: CLLocationCoordinate2D
    let state: UserState
    
    // MARK: - Live Tracking Fields
    let sessionId: String
    /// UID of the person in emergency (the active user being tracked)
    let userId: String
    let destinationName: String?
    let destinationLatitude: Double?
    let destinationLongitude: Double?

    init(
        id: UUID = UUID(),
        name: String,
        startedAt: String,
        route: String,
        eta: String,
        distance: String,
        coordinate: CLLocationCoordinate2D,
        state: UserState = .OnTheWay,
        sessionId: String = "",
        userId: String = "",
        destinationName: String? = nil,
        destinationLatitude: Double? = nil,
        destinationLongitude: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.route = route
        self.eta = eta
        self.distance = distance
        self.coordinate = coordinate
        self.state = state
        self.sessionId = sessionId
        self.userId = userId
        self.destinationName = destinationName
        self.destinationLatitude = destinationLatitude
        self.destinationLongitude = destinationLongitude
    }
}
