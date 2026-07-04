//
//  File.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 03/07/26.
//

import Foundation
import CoreLocation

struct UserLocation: Identifiable{
    let id = UUID()
    let nama: String
    let coordinate: CLLocationCoordinate2D
    let state: UserState
}
