//
//  File.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 04/07/26.
//

import Foundation
import CoreLocation

struct SafeLocation: Identifiable{
    let id = UUID()
    let safeAddress: CLLocationCoordinate2D
}

