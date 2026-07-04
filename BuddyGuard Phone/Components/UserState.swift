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
}

func getUserState(from state: UserState) -> String{
    switch state{
    case .OnTheWay:
        return "On The Way"
    case .Arrived:
        return "Arrived"
    case .Urgent:
        return "Urgent"
    }
}

func getUserStateColor(from state: UserState) -> Color{
    switch state{
    case .OnTheWay:
        return .statusYellow
    case .Arrived:
        return .statusGreen
    case .Urgent:
        return .statusRed
    }
}

func getUserStateStrokeColor(from state: UserState) -> Color{
    switch state{
    case .OnTheWay:
        return Color(red:245/255 ,green:226/255 ,blue:85/255 )
    case .Arrived:
        return Color(red:48/255 ,green:209/255 ,blue:88/255 )
    case .Urgent:
        return Color(red:255/255 ,green:66/255 ,blue:69/255 )
    }
}
