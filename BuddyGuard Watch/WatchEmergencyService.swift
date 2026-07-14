//
//  WatchEmergencyService.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by George Maximillian Theodore on 13/07/26.
//

import Foundation
import CoreLocation
import WatchConnectivity

/// Coordinates the Watch emergency flow:
///
/// 1. **Calls the Cloudflare Worker directly** (plain URLSession — no Firebase Auth needed)
///    so emergency contacts are notified even if the phone is temporarily unreachable.
/// 2. **Sends WatchConnectivity messages to the phone** so the phone creates the Firestore
///    session and starts the Live Activity / Dynamic Island.
@Observable
class WatchEmergencyService {

    // MARK: - Public State
    var isActive: Bool = false
    var sessionId: String?

    // MARK: - Private
    private let workerURL = URL(string: "https://buddyguard-push-notif.george-maximillian.workers.dev/")!

    // MARK: - Start Emergency

    /// Triggers the full emergency flow. Call this once when the user activates emergency mode.
    func startEmergency(coordinate: CLLocationCoordinate2D) {
        guard !isActive else { return }
        isActive = true

        let userSession = WatchUserSession.shared

        // 1. Tell the phone to create the Firestore session and start Live Activity.
        //    We use DUAL-CHANNEL delivery for maximum reliability:
        //    - sendMessage: real-time, can return the sessionId via replyHandler
        //    - transferUserInfo: guaranteed queued delivery, even if phone is backgrounded
        //    The phone's handleAction is idempotent so receiving duplicates is safe.
        let message: [String: Any] = [
            "action":    "startSession",
            "latitude":  coordinate.latitude,
            "longitude": coordinate.longitude
        ]
        let session = WCSession.default

        // Always queue via transferUserInfo as a guaranteed backup — this never times out.
        session.transferUserInfo(message)
        print("📤 WatchEmergencyService: startSession queued via transferUserInfo (guaranteed)")

        // Additionally attempt sendMessage for real-time session ID reply.
        if session.isReachable {
            sendMessageWithRetry(message, session: session, retriesLeft: 1)
        } else {
            print("📵 WatchEmergencyService: Phone not reachable — relying on transferUserInfo")
        }

        // 2. Independently notify emergency contacts via the Cloudflare Worker.
        //    This does NOT require the phone to be reachable — pure URLSession.
        let tokens = userSession.alertableTokens
        guard !tokens.isEmpty else {
            // This is expected on first launch before the phone has pushed user context.
            // Contacts will still be notified by the phone when it handles the startSession message.
            print("ℹ️ WatchEmergencyService: No cached FCM tokens — phone will handle contact notifications.")
            return
        }
        let tempAlertId = UUID().uuidString
        triggerCloudflareAlert(
            alertId:          tempAlertId,
            senderName:       userSession.displayName,
            tokens:           tokens,
            notificationType: "emergency_start"
        )
    }

    /// Attempts `sendMessage` with a retry on timeout. Gives up after `retriesLeft` retries.
    private func sendMessageWithRetry(_ message: [String: Any],
                                       session: WCSession,
                                       retriesLeft: Int) {
        session.sendMessage(message, replyHandler: { [weak self] reply in
            if let sid = reply["sessionId"] as? String, !sid.isEmpty {
                DispatchQueue.main.async {
                    self?.sessionId = sid
                    WatchUserSession.shared.activeSessionId = sid
                    print("✅ WatchEmergencyService: Session \(sid) confirmed from phone (real-time)")
                }
            }
        }, errorHandler: { [weak self] error in
            if retriesLeft > 0 {
                print("⚠️ WatchEmergencyService: sendMessage failed — \(error.localizedDescription). Retrying in 1s…")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    guard session.isReachable else {
                        print("📵 WatchEmergencyService: Phone no longer reachable after retry delay")
                        return
                    }
                    self?.sendMessageWithRetry(message, session: session, retriesLeft: retriesLeft - 1)
                }
            } else {
                print("⚠️ WatchEmergencyService: sendMessage failed after retry — \(error.localizedDescription). transferUserInfo already queued.")
            }
        })
    }

    // MARK: - Upload Location (throttled on WatchConnector side)

    func uploadLocation(_ coordinate: CLLocationCoordinate2D) {
        guard isActive else { return }
        sendToPhone([
            "action":    "uploadLocation",
            "latitude":  coordinate.latitude,
            "longitude": coordinate.longitude
        ])
    }

    // MARK: - Update Destination

    func updateDestination(name: String, coordinate: CLLocationCoordinate2D) {
        sendToPhone([
            "action":    "updateDestination",
            "name":      name,
            "latitude":  coordinate.latitude,
            "longitude": coordinate.longitude
        ])
    }

    // MARK: - Update Status

    func updateStatus(_ status: UserState) {
        sendToPhone([
            "action": "updateStatus",
            "status": status.rawValue
        ])
        if status == .Arrived {
            isActive = false
            sessionId = nil
            WatchUserSession.shared.activeSessionId = nil
        }
    }

    // MARK: - Stop Session

    func stopSession() {
        updateStatus(.Arrived)
    }

    // MARK: - Private Helpers

    /// Sends a message to the phone using dual-channel delivery for reliability.
    /// sendMessage provides real-time delivery; transferUserInfo provides guaranteed queued delivery.
    private func sendToPhone(_ message: [String: Any]) {
        let session = WCSession.default
        // Always queue as guaranteed backup
        session.transferUserInfo(message)
        // Attempt real-time delivery if phone is reachable
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("⚠️ WatchEmergencyService: sendMessage failed for \(message["action"] ?? "unknown") — \(error.localizedDescription). transferUserInfo already queued.")
            })
        }
    }

    private func triggerCloudflareAlert(alertId: String,
                                        senderName: String,
                                        tokens: [String],
                                        notificationType: String) {
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "notificationType": notificationType,
            "senderId":         WatchUserSession.shared.uid ?? "unknown",
            "alertId":          alertId,
            "senderName":       senderName,
            "friendTokens":     tokens
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("🚨 WatchEmergencyService: Cloudflare Worker call failed — \(error.localizedDescription)")
            } else if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                print("✅ WatchEmergencyService: Emergency alert sent to contacts!")
            } else {
                print("⚠️ WatchEmergencyService: Cloudflare Worker returned unexpected response")
            }
        }.resume()
    }
}
