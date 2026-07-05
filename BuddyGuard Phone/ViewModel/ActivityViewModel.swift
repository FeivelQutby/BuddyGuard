//
//  ActivityViewModel.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import CoreLocation
import Foundation
import Observation

@Observable
final class ActivityViewModel {
    var requests: [ActivityRequest]

    init(requests: [ActivityRequest] = ActivityViewModel.sampleRequests) {
        self.requests = requests
    }
    
//    init(requests: [ActivityRequest] = []) {
//        self.requests = requests
//    }


    func startTracking(_ request: ActivityRequest) {
        // Hook live tracking flow here when the tracking screen is ready.
    }
}

extension ActivityViewModel {
    static let sampleRequests = [
        ActivityRequest(
            name: "Maya",
            startedAt: "Started at 10.00 PM",
            route: "GOP 9 -> Indomaret Foresta",
            eta: "ETA 22.10",
            distance: "1,2 km",
            coordinate: CLLocationCoordinate2D(latitude: -6.3024, longitude: 106.6527)
        ),
        ActivityRequest(
            name: "Clarice",
            startedAt: "Started at 9.50 PM",
            route: "Ice Business -> Alfamart Ice",
            eta: "ETA 22.00",
            distance: "1,2 km",
            coordinate: CLLocationCoordinate2D(latitude: -6.3024, longitude: 106.6527)
        )
    ]
}
