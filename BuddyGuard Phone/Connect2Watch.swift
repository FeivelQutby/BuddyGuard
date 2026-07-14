//
//  Connect2Watch.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 11/07/26.
//

import Foundation
import WatchConnectivity
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

/// Phone-side WatchConnectivity bridge.
///
/// Responsibilities:
/// - Receives emergency action messages from the Watch and delegates them to a `LiveTrackingManager`.
/// - Pushes fresh user context (UID, display name, FCM alert tokens) to the Watch whenever
///   the user logs in or the WCSession activates.
/// - Clears the Watch's cached context on logout.
class PhoneConnector: NSObject, WCSessionDelegate {

    // MARK: - Singleton
    static let shared = PhoneConnector()

    /// Holds the `LiveTrackingManager` created for Watch-triggered sessions.
    /// The phone's `EmergencyView` creates its own instance when it resumes the same session
    /// from Firestore — both write idempotent data, so there is no conflict.
    private var liveTrackingManager: LiveTrackingManager?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send User Context to Watch

    /// Fetches the current user's alertable FCM tokens from Firestore and sends the full
    /// user context to the paired Watch via multiple delivery methods for maximum reliability:
    /// - `updateApplicationContext`: persists on Watch across restarts, delivered on next connection.
    /// - `transferUserInfo`: reliable queued delivery as a secondary backup.
    func sendUserContext() {
        guard WCSession.default.activationState == .activated else { return }
        guard let user = Auth.auth().currentUser else { return }

        Task {
            let tokens = await EmergencyContactManager().fetchFCMTokensForAlertableContacts()
            let payload: [String: Any] = [
                "action":           "userContext",
                "uid":              user.uid,
                "displayName":      user.displayName ?? "User",
                "alertableTokens":  tokens
            ]

            // 1. updateApplicationContext — most reliable: persists on Watch across restarts,
            //    delivered immediately when the Watch connects. Never times out.
            do {
                try WCSession.default.updateApplicationContext(payload)
            } catch {
                print("⚠️ PhoneConnector: updateApplicationContext failed — \(error.localizedDescription)")
            }

            // 2. transferUserInfo — queued, guaranteed delivery even while Watch is backgrounded.
            WCSession.default.transferUserInfo(payload)

            print("✅ PhoneConnector: User context pushed to Watch (\(tokens.count) FCM token(s))")
        }
    }

    /// Tells the Watch to clear its cached user context (called on logout).
    func notifyWatchLogout() {
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo(["action": "userLoggedOut"])
    }

    // MARK: - WCSessionDelegate — Activation

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("📡 PhoneConnector: WCSession activation = \(activationState.rawValue), error = \(error?.localizedDescription ?? "none")")
        if activationState == .activated {
            sendUserContext()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📡 PhoneConnector: WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("📡 PhoneConnector: WCSession deactivated — reactivating")
        session.activate()
    }

    // MARK: - WCSessionDelegate — Receive real-time messages from Watch

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        print("📩 PhoneConnector: didReceiveMessage (real-time) — \(message["action"] ?? "unknown")")
        handleAction(from: message, reply: replyHandler)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("📩 PhoneConnector: didReceiveMessage (no reply) — \(message["action"] ?? "unknown")")
        handleAction(from: message, reply: nil)
    }

    // MARK: - WCSessionDelegate — Receive queued userInfo from Watch

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        print("📦 PhoneConnector: didReceiveUserInfo — \(userInfo["action"] ?? "unknown")")
        handleAction(from: userInfo, reply: nil)
    }

    // MARK: - Action Dispatch

    private func handleAction(from payload: [String: Any],
                              reply: (([String: Any]) -> Void)?) {
        guard let action = payload["action"] as? String else {
            print("⚠️ PhoneConnector: Received payload with no 'action' key — \(payload)")
            reply?([:])
            return
        }

        print("🔧 PhoneConnector: Handling action '\(action)' on thread=\(Thread.isMainThread ? "main" : "bg")")

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            switch action {

            case "startSession":
                guard let lat = payload["latitude"] as? Double,
                      let lng = payload["longitude"] as? Double else {
                    print("⚠️ PhoneConnector: startSession missing lat/lng")
                    reply?([:])
                    return
                }
                // Deduplication: if a session is already active (from a prior sendMessage or
                // transferUserInfo), reply with the existing sessionId instead of creating a new one.
                if let existing = self.liveTrackingManager, existing.isActive,
                   let existingId = existing.sessionId {
                    print("ℹ️ PhoneConnector: Duplicate startSession — returning existing session '\(existingId)'")
                    reply?(["sessionId": existingId])
                    return
                }
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                print("🚀 PhoneConnector: Starting session at (\(lat), \(lng))")

                // Firebase Auth can be nil briefly when the phone app is woken from background.
                // Wait up to 5 s for Auth to restore, then proceed.
                self.startSessionWhenAuthenticated(coordinate: coord, reply: reply)

            case "uploadLocation":
                guard let lat = payload["latitude"] as? Double,
                      let lng = payload["longitude"] as? Double else { return }
                print("📍 PhoneConnector: Uploading location (\(lat), \(lng))")
                self.liveTrackingManager?.uploadLocation(
                    CLLocationCoordinate2D(latitude: lat, longitude: lng)
                )

            case "updateDestination":
                guard let name = payload["name"] as? String,
                      let lat  = payload["latitude"] as? Double,
                      let lng  = payload["longitude"] as? Double else { return }
                print("📍 PhoneConnector: Updating destination '\(name)'")
                self.liveTrackingManager?.updateDestination(
                    name: name,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                )

            case "updateStatus":
                guard let raw    = payload["status"] as? String,
                      let status = UserState(rawValue: raw) else { return }
                print("🔄 PhoneConnector: Updating status → \(raw)")
                self.liveTrackingManager?.updateStatus(status)
                if status == .Arrived {
                    self.liveTrackingManager = nil
                }

            case "requestUserContext":
                print("📩 PhoneConnector: Watch requested user context — pushing now")
                self.sendUserContext()
                reply?([:])

            default:
                print("⚠️ PhoneConnector: Unknown action '\(action)'")
                reply?([:])
            }
        }
    }

    /// Waits for Firebase Auth to have a current user (handles the background-wake race),
    /// then starts the session. Gives up after 5 seconds.
    private func startSessionWhenAuthenticated(coordinate: CLLocationCoordinate2D,
                                               reply: (([String: Any]) -> Void)?,
                                               attempt: Int = 0) {
        if let _ = Auth.auth().currentUser {
            let manager = LiveTrackingManager()
            self.liveTrackingManager = manager
            manager.startSession(coordinate: coordinate)

            let sessionId = manager.sessionId ?? ""
            print("✅ PhoneConnector: Session '\(sessionId)' created from Watch trigger")
            reply?(["sessionId": sessionId])

            let sessionPayload: [String: Any] = [
                "action":    "sessionStarted",
                "sessionId": sessionId
            ]
            // transferUserInfo — reliable queued delivery
            WCSession.default.transferUserInfo(sessionPayload)
            // sendMessage — real-time if reachable
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(sessionPayload, replyHandler: nil, errorHandler: nil)
            }
        } else if attempt < 10 {
            // Auth not ready yet — retry in 500 ms (max 5 s total)
            print("⏳ PhoneConnector: Auth.currentUser nil, retrying in 0.5s (attempt \(attempt + 1)/10)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.startSessionWhenAuthenticated(coordinate: coordinate, reply: reply, attempt: attempt + 1)
            }
        } else {
            print("🚨 PhoneConnector: Auth.currentUser still nil after 5s — session NOT created. Is user logged in on phone?")
            reply?([:])
        }
    }
}
