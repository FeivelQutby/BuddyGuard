//
//  UserState.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 03/07/26.
//

import Foundation
import SwiftUI

enum UserState: String{
    case OnTheWay
    case Arrived
    case Urgent
    
    var label: String {
        switch self {
        case .OnTheWay: return "On The Way"
        case .Arrived: return "Arrived"
        case .Urgent: return "Urgent"
        }
    }
    
    var fillColor: Color {
        switch self {
        case .OnTheWay: return .yellow
        case .Arrived: return .green
        case .Urgent: return .red
        }
    }
    
    var strokeColor: Color {
        switch self {
        case .OnTheWay: return .yellow
        case .Arrived: return .green
        case .Urgent: return .red
        }
    }
}
