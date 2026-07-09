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
        case .Arrived: return "Arrived safely"
        case .Urgent: return "Need help!"
        }
    }
    
    var iconName: String {
        switch self {
        case .OnTheWay: return "clock.fill"
        case .Arrived: return "checkmark.circle.fill"
        case .Urgent: return "exclamationmark.triangle.fill"
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
