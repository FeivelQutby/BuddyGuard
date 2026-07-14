//
//  AppDelegate.swift
//  BuddyGuard
//
//  Created by George Maximillian Theodore on 08/07/26.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

// Create the AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        // MARK: - WatchConnectivity Bridge
        // Touching the singleton here activates WCSession immediately at launch,
        // so no Watch messages are dropped before the first view appears.
        _ = PhoneConnector.shared
        
        // MARK: - FCM Delegate
        // Required so FCM can receive the APNs token and exchange it for an FCM token.
        Messaging.messaging().delegate = self
        
        // MARK: - Notification Permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.main.async {
            application.registerForRemoteNotifications()
        }
        
        return true
    }
    
    // MARK: - APNs Token → Hand Off to FCM
    // Do NOT save the raw APNs token to Firestore — FCM needs it to produce its own FCM token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("APNs token handed to FCM ✅")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register with APNs: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - MessagingDelegate
// This fires whenever FCM generates or refreshes the FCM token.
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCM Token: \(fcmToken)")
        
        // Persist FCM token under the authenticated user's document
        guard let currentUID = Auth.auth().currentUser?.uid else {
            // Not logged in yet — token will be saved again on login via LoginView
            print("ℹ️ FCM token received before login — will be saved after authentication.")
            return
        }
        
        saveFCMToken(fcmToken, forUID: currentUID)
    }
    
    func saveFCMToken(_ token: String, forUID uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData(["fcmToken": token], merge: true) { error in
            if let error = error {
                print("⚠️ Failed to save FCM token: \(error.localizedDescription)")
            } else {
                print("✅ FCM Token saved to Firestore for user \(uid)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
// Shows notification banners even when the app is in the foreground.
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// Shows banners/sound/badge even while the app is foregrounded.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Fires when the user TAPS a notification (app backgrounded or cold-launched).
    /// Routes to the appropriate screen via DeepLinkRouter.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        DispatchQueue.main.async {
            DeepLinkRouter.shared.handle(userInfo: userInfo)
        }
        completionHandler()
    }
}
