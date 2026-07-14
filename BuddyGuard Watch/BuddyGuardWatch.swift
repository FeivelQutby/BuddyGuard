//
//  BuddyGuardWatch.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 26/06/26.
//

import SwiftUI

@main
struct BuddyGuardWatch: App {
    init() {
        // Activate WCSession immediately at launch so no incoming messages are missed.
        _ = WatchConnector.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

