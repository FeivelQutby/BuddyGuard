//
//  EmergencyView.swift
//  BuddyGuard
//
//  Created by George Maximillian Theodore on 03/07/26.
//

import SwiftUI
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Emergency View
struct EmergencyView: View {
    @Environment(DeepLinkRouter.self) private var deepLinkRouter

    @State private var progress: CGFloat = 0.0
    @State private var timeElapsed: Double = 0.0
    @State private var isPressing = false
    @State private var timer: Timer?
    @State private var showMap = false
    @State private var lastTickSecond: Int = 0

    @State private var showCancelledToast = false
    @State private var showEndedToast = false

    @State private var locationManager = LocationManager()
    @State private var liveTrackingManager = LiveTrackingManager()
    
    /// True while we're checking Firestore for a resumable session (avoids flash of empty UI).
    @State private var isCheckingSession = true
    private var viewModel = ProfileViewModel()
    var body: some View {
        
        VStack (spacing: 64) {
            
            Divider().opacity(0)
            
            VStack {
                // MARK: - Tooltip
                VStack(spacing: 0) {
                    Text("**Press & Hold me** for 3s to \nactivate navigation mode")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.darkActiveNd)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .background(.light)
                        .cornerRadius(16)
                    
                    Image(systemName: "arrowtriangle.down.fill")
                        .foregroundStyle(.light)
                        .font(.largeTitle)
                        .offset(y: -10)
                }
                
                // MARK: - Animated Interactive Button
                Image("mascot")
                    .frame(width: 250, height: 250)
                    .foregroundStyle(.dark)
                    .padding(24)
                    .overlay(
                        Circle()
                            .trim(from: 0.0, to: progress)
                            .stroke(Color(red: 0x39/255.0, green: 0x32/255.0, blue: 0x8F/255.0), lineWidth: 22)
                            .rotationEffect(.degrees(-90))
                    )
                    .overlay(
                        Circle()
                            .trim(from: 0.0, to: progress)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0x61/255.0, green: 0x55/255.0, blue: 0xF5/255.0),
                                             Color(red: 0x39/255.0, green: 0x32/255.0, blue: 0x8F/255.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(color: Color(red: 0x61/255.0, green: 0x55/255.0, blue: 0xF5/255.0).opacity(0.6), radius: 10, x: 0, y: 4)
                    )
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isPressing { startHolding() }
                            }
                            .onEnded { _ in
                                stopHolding()
                            }
                        
                    )
                    .background(
                        Image("effect")
                    )
                
                // MARK: - Dynamic Timer Display
                if isPressing {
                    VStack(spacing: 4) {
                        Text(String(format: "%05.2fs", timeElapsed))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.darkActive)
                        
                        Text("Release the button to cancel!")
                            .font(.footnote)
                            .foregroundStyle(.darkActive)
                    }
                    .padding(.top, 24)
                    .transition(.opacity) // Smooth fade in/out
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isPressing)
            
            
            
            if viewModel.emergencyContacts.isEmpty {
                NoContact()
//                Divider().opacity(0)
            } else {
//                NoContact()
                Divider().opacity(0)
            }
            
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .fullScreenCover(isPresented: $showMap, onDismiss: {
            stopHolding()
            HapticManager.notification(.success)
            showEndedToast = true
        }) {
            MapView(role: .activeUser, liveTrackingManager: liveTrackingManager)
        }
        .toast(isPresented: $showCancelledToast, icon: "xmark.circle.fill", message: "Emergency cancelled", tint: .secondary)
        .toast(isPresented: $showEndedToast, icon: "shield.checkmark.fill", message: "Emergency session ended. You're safe.", duration: 3.0)
        // ── Session Resume ────────────────────────────────────────────────
        // If the user had an active emergency session when the app was killed
        // (e.g. they tapped away after receiving a 'contact_on_way' notification),
        // resume the session and re-open MapView automatically.
        .onAppear {
            Task { await resumeActiveSessionIfNeeded() }
        }
        .onChange(of: deepLinkRouter.triggerEmergency) { _, trigger in
            if trigger {
                deepLinkRouter.triggerEmergency = false
                triggerInstantEmergency()
            }
        }
    }
    
    // MARK: - Session Resume
    
    /// Checks Firestore for an active tracking session owned by the current user.
    /// If found, restores LiveTrackingManager state and re-opens MapView.
    @MainActor
    private func resumeActiveSessionIfNeeded() async {
        defer { isCheckingSession = false }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("tracking_sessions")
                .whereField("userId", isEqualTo: uid)
                .whereField("isActive", isEqualTo: true)
                .limit(to: 1)
                .getDocuments()
            
            guard let doc = snapshot.documents.first else { return }
            let sessionId = doc.data()["sessionId"] as? String ?? doc.documentID
            
            // Restore the manager's session state so MapView can continue
            // broadcasting location / receiving status updates.
            liveTrackingManager.sessionId = sessionId
            liveTrackingManager.isActive = true
            showMap = true
            print("✅ EmergencyView: Resumed active session \(sessionId)")
        } catch {
            print("⚠️ EmergencyView: Session resume check failed — \(error.localizedDescription)")
        }
    }
    
    // MARK: - Animation Control Logic
    private func startHolding() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isPressing = true
        }
        progress = 0.0
        timeElapsed = 0.0
        lastTickSecond = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            timeElapsed += 0.01
            
            let currentSecond = Int(timeElapsed)
            if currentSecond > lastTickSecond && currentSecond < 3 {
                lastTickSecond = currentSecond
                HapticManager.impact(.light)
            }
            
            if timeElapsed >= 3.0 {
                timeElapsed = 3.0
                progress = 1.0
                timer?.invalidate()
                
                HapticManager.notification(.success)
                showMap = true
                
                if let coord = locationManager.coordinate {
                    liveTrackingManager.startSession(coordinate: coord)
                }
                
                // Fire emergency start notification to all alertable contacts
                let trackingManager = liveTrackingManager
                Task { @MainActor in
                    let contactManager = EmergencyContactManager()
                    let tokens = await contactManager.fetchFCMTokensForAlertableContacts()
                    guard !tokens.isEmpty else {
                        print("ℹ️ No alertable contacts with FCM tokens found.")
                        return
                    }
                    let senderName = Auth.auth().currentUser?.displayName ?? "Your Friend"
                    let alertId = trackingManager.sessionId ?? UUID().uuidString
                    trackingManager.triggerEmergencyAlert(
                        alertId: alertId,
                        senderName: senderName,
                        friendTokens: tokens,
                        notificationType: "emergency_start"
                    )
                }
            } else {
                progress = CGFloat(timeElapsed / 3.0)
            }
        }
    }
    
    private func triggerInstantEmergency() {
        guard !showMap, !liveTrackingManager.isActive else { return }

        HapticManager.notification(.success)
        showMap = true

        if let coord = locationManager.coordinate {
            liveTrackingManager.startSession(coordinate: coord)
        }

        let trackingManager = liveTrackingManager
        Task { @MainActor in
            let contactManager = EmergencyContactManager()
            let tokens = await contactManager.fetchFCMTokensForAlertableContacts()
            guard !tokens.isEmpty else { return }
            let senderName = Auth.auth().currentUser?.displayName ?? "Your Friend"
            let alertId = trackingManager.sessionId ?? UUID().uuidString
            trackingManager.triggerEmergencyAlert(
                alertId: alertId,
                senderName: senderName,
                friendTokens: tokens,
                notificationType: "emergency_start"
            )
        }
    }

    private func stopHolding() {
        let wasCancelled = isPressing && timeElapsed < 3.0 && timeElapsed > 0.3
        
        timer?.invalidate()
        timer = nil
        
        if wasCancelled {
            HapticManager.impact(.soft)
            showCancelledToast = true
        }
        
        withAnimation(.easeInOut(duration: 0.25)) {
            isPressing = false
            progress = 0.0
            timeElapsed = 0.0
        }
    }
}

#Preview("Light") {
    EmergencyView()
        .environment(DeepLinkRouter.shared)
}

#Preview("Dark") {
    EmergencyView()
        .preferredColorScheme(.dark)
        .environment(DeepLinkRouter.shared)
}
