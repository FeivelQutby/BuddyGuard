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
                            .stroke(.darkActive, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .rotationEffect(.degrees(-90))
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
            
            Divider().opacity(0)
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
                Task {
                    let contactManager = await EmergencyContactManager()
                    let tokens = await contactManager.fetchFCMTokensForAlertableContacts()
                    guard !tokens.isEmpty else {
                        print("ℹ️ No alertable contacts with FCM tokens found.")
                        return
                    }
                    let senderName = Auth.auth().currentUser?.displayName ?? "Your Friend"
                    let alertId = await trackingManager.sessionId ?? UUID().uuidString
                    await trackingManager.triggerEmergencyAlert(
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
}

#Preview("Dark") {
    EmergencyView()
        .preferredColorScheme(.dark)
}
