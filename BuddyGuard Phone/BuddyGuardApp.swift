//
//  BuddyGuardApp.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 26/06/26.
//

import SwiftUI

@main
struct BuddyGuardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#Preview("Light Mode") {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
    .preferredColorScheme(.dark)
}
