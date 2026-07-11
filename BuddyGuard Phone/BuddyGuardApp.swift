//
//  BuddyGuardApp.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 26/06/26.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn


@main
struct BuddyGuardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Initialize the listener
    @State private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                // The routing logic
                if authManager.isAuthenticated {
                    ContentView()
                        .environment(authManager)
                        .environment(DeepLinkRouter.shared)
                } else {
                    LoginView()
                        .onOpenURL { url in
                            GIDSignIn.sharedInstance.handle(url)
                        }
                }
            }
            .onAppear {
                authManager.startListening()
            }
        }
    }
}

#Preview("Light Mode") {
    ContentView().environment(AuthManager()).environment(DeepLinkRouter.shared)
    ContentView()
        .environment(AuthManager())
        .environment(DeepLinkRouter.shared)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
        .environment(AuthManager())
        .environment(DeepLinkRouter.shared)
}
