//
//  BuddyGuardApp.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 26/06/26.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

// Create the AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

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
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
    .preferredColorScheme(.dark)
}
