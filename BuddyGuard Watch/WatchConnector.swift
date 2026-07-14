//
//  WatchConnector.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Benedicta Joyce Sutandyo on 09/07/26.
//

import Foundation
import WatchConnectivity
import CoreLocation

/// Watch-side WatchConnectivity singleton.
///
/// Outbound: sends emergency actions to the phone using `sendMessage` (real-time) with
/// `transferUserInfo` as a reliable queued fallback.
///
/// Inbound: receives user context (UID, display name, FCM tokens) pushed by the phone
/// and stores it in `WatchUserSession` for offline use.
class WatchConnector: NSObject, WCSessionDelegate {
    static let shared = WatchConnector()
    var session: WCSession

    init(session: WCSession = .default) {
        self.session = session
        super.init()
        session.delegate = self
        session.activate()
    }

    // MARK: - Delegate — Activation

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: (any Error)?) {
        if let error {
            print("⚠️ WatchConnector: WCSession activation error — \(error.localizedDescription)")
        } else {
            print("✅ WatchConnector: WCSession activated (\(activationState))")
        }
        // Read the last application context the phone pushed — this is persisted across
        // Watch restarts, so credentials are available immediately without waiting for a new push.
        let ctx = session.receivedApplicationContext
        if !ctx.isEmpty {
            DispatchQueue.main.async { self.handleIncoming(ctx) }
        }

        // If the Watch still has no cached UID after reading applicationContext,
        // proactively request a fresh user context push from the phone.
        if WatchUserSession.shared.uid == nil {
            let request: [String: Any] = ["action": "requestUserContext"]
            if session.isReachable {
                session.sendMessage(request, replyHandler: nil, errorHandler: { _ in
                    session.transferUserInfo(request)
                })
            } else {
                session.transferUserInfo(request)
            }
            print("📤 WatchConnector: No cached UID — requested user context from phone")
        }
    }

    // MARK: - Receive from Phone

    /// Handles context / session info pushed from the phone via queued transferUserInfo.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleIncoming(userInfo)
    }

    /// Handles real-time messages pushed from the phone via sendMessage.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.handleIncoming(message) }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async { self.handleIncoming(message) }
        replyHandler([:])
    }

    /// Handles application context updates pushed from the phone.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.handleIncoming(applicationContext) }
    }

    // MARK: - Shared Incoming Handler

    private func handleIncoming(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else { return }

        switch action {
        case "userContext":
            if let uid = payload["uid"] as? String {
                WatchUserSession.shared.uid = uid
            }
            if let name = payload["displayName"] as? String {
                WatchUserSession.shared.displayName = name
            }
            if let tokens = payload["alertableTokens"] as? [String] {
                WatchUserSession.shared.alertableTokens = tokens
            }
            print("✅ WatchConnector: User context received from phone (\(WatchUserSession.shared.alertableTokens.count) token(s))")

        case "sessionStarted":
            if let sid = payload["sessionId"] as? String, !sid.isEmpty {
                DispatchQueue.main.async {
                    WatchUserSession.shared.activeSessionId = sid
                    print("✅ WatchConnector: Session ID \(sid) received from phone")
                }
            }

        case "userLoggedOut":
            WatchUserSession.shared.clear()
            print("✅ WatchConnector: User logged out — Watch context cleared")

        default:
            break
        }
    }

    // MARK: - Send to Phone (convenience wrappers used by legacy call sites)

    func sendStartSession(with coordinate: CLLocationCoordinate2D) {
        send([
            "action":    "startSession",
            "latitude":  coordinate.latitude,
            "longitude": coordinate.longitude
        ])
    }

    func sendUploadLocation(with coordinate: CLLocationCoordinate2D) {
        send([
            "action":    "uploadLocation",
            "latitude":  coordinate.latitude,
            "longitude": coordinate.longitude
        ])
    }

    func sendUpdateDestination(name: String, coordinate: CLLocationCoordinate2D) {
        send([
            "action":    "updateDestination",
            "name":      name,
            "latitude":  coordinate.latitude,
            "longitude": coordinate.longitude
        ])
    }

    func sendUpdateStatus(_ status: UserState) {
        send([
            "action": "updateStatus",
            "status": status.rawValue
        ])
    }

    // MARK: - Private

    private func send(_ message: [String: Any]) {
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                // Fallback to queued delivery on failure
                self.session.transferUserInfo(message)
                print("⚠️ WatchConnector: sendMessage failed, queued via transferUserInfo — \(error.localizedDescription)")
            }
        } else {
            session.transferUserInfo(message)
        }
    }
}
