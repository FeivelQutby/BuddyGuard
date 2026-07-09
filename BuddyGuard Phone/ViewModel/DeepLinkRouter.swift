//
//  DeepLinkRouter.swift
//  BuddyGuard
//
//  Created by George Maximillian Theodore on 09/07/26.
//

import Foundation
import Observation

/// Bridges AppDelegate notification taps to SwiftUI navigation.
///
/// Usage:
///   - AppDelegate calls `DeepLinkRouter.shared.handle(userInfo:)` when a notification is tapped.
///   - ContentView reads `selectedTab` to switch tabs.
///   - ActivityView reads `pendingSessionId` to auto-open MapView for the right session.
@Observable
final class DeepLinkRouter {
    
    // MARK: - Singleton
    static let shared = DeepLinkRouter()
    private init() {}
    
    // MARK: - State
    
    /// The tab index to switch to (0 = Emergency, 1 = Activity, 2 = Profile).
    var selectedTab: Int = 0
    
    /// The `sessionId` / `alertId` from the notification payload.
    /// Set to non-nil to trigger MapView open in ActivityView.
    /// Must be consumed (set back to nil) after use.
    var pendingSessionId: String? = nil
    
    // MARK: - Handle Notification Tap
    
    /// Called from AppDelegate when the user taps a notification.
    /// Parses the FCM `data` payload and sets the appropriate navigation state.
    func handle(userInfo: [AnyHashable: Any]) {
        let notificationType = userInfo["notificationType"] as? String ?? ""
        let alertId = userInfo["alertId"] as? String ?? ""
        
        switch notificationType {
        
        // Emergency contact receives these → open Activity tab → auto-open MapView
        case "emergency_start", "sos":
            pendingSessionId = alertId.isEmpty ? nil : alertId
            selectedTab = 1
            
        // Emergency contact receives im_safe → switch to Activity tab, no MapView
        case "im_safe":
            pendingSessionId = nil
            selectedTab = 1
            
        // Active user receives contact_on_way → no navigation change needed
        // (they're already in MapView; session-resume in EmergencyView handles killed state)
        case "contact_on_way":
            break
            
        default:
            break
        }
    }
}
