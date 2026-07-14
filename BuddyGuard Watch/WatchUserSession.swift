//
//  WatchUserSession.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by George Maximillian Theodore on 13/07/26.
//

import Foundation

/// UserDefaults-backed singleton that stores the authenticated user's context on the Watch.
/// Populated by the phone via WatchConnectivity whenever the user logs in or contacts change.
/// Persists across app restarts so the Watch can trigger emergencies without re-pairing.
class WatchUserSession {
    static let shared = WatchUserSession()
    private init() {}

    private let defaults = UserDefaults.standard
    private enum Key {
        static let uid              = "watch_uid"
        static let displayName      = "watch_displayName"
        static let alertableTokens  = "watch_alertableTokens"
        static let activeSessionId  = "watch_activeSessionId"
    }

    // MARK: - User Identity

    var uid: String? {
        get { defaults.string(forKey: Key.uid) }
        set { defaults.set(newValue, forKey: Key.uid) }
    }

    var displayName: String {
        get { defaults.string(forKey: Key.displayName) ?? "User" }
        set { defaults.set(newValue, forKey: Key.displayName) }
    }

    // MARK: - FCM Tokens for alertable contacts (pre-fetched by the phone)

    var alertableTokens: [String] {
        get { defaults.stringArray(forKey: Key.alertableTokens) ?? [] }
        set { defaults.set(newValue, forKey: Key.alertableTokens) }
    }

    // MARK: - Active Emergency Session

    var activeSessionId: String? {
        get { defaults.string(forKey: Key.activeSessionId) }
        set { defaults.set(newValue, forKey: Key.activeSessionId) }
    }

    // MARK: - Clear on logout

    func clear() {
        defaults.removeObject(forKey: Key.uid)
        defaults.removeObject(forKey: Key.displayName)
        defaults.removeObject(forKey: Key.alertableTokens)
        defaults.removeObject(forKey: Key.activeSessionId)
        print("✅ WatchUserSession: Cleared on logout")
    }
}

// MARK: - WatchAppState (shared observable for Siri / AppIntent triggers)

/// Observable singleton used by ContentView to react to Siri / AppIntent emergency triggers.
@Observable
class WatchAppState {
    static let shared = WatchAppState()
    private init() {}
    var shouldTriggerEmergency: Bool = false
}
