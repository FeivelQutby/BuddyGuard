//
//  ContentView.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Feivel Qutby on 26/06/26.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    // MARK: - State
    @State private var showDirection: Bool = false
    @State private var showArriveConfirmation: Bool = false
    @State private var isPressing: Bool = false
    @State private var progress: CGFloat = 0.0
    @State private var timeElapsed: Double = 0.0
    @State private var lastTickSecond: Int = 0
    @State private var timer: Timer?
    @State private var locationManager = LocationManager()
    /// Shared routeManager passed into both DirectionView and FalseAlaramView
    @State private var routeManager = RouteManager()
    @State private var emergencyService = WatchEmergencyService()
    @State private var showCancelledToast = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("**Press & Hold me** for 3s to \nactivate navigation mode")
                        .font(.system(size: 10))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.darkActiveNd)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .background(.light)
                        .cornerRadius(16)

                    Image(systemName: "arrowtriangle.down.fill")
                        .foregroundStyle(.light)
                        .font(.title2)
                        .offset(y: -10)
                }
                .offset(y: -10)

                Image("mascot")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .offset(y: -10)
                    .foregroundStyle(.dark)
                    .overlay(
                        Circle()
                            .trim(from: 0.0, to: progress)
                            .stroke(.darkActive, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 120, height: 120)
                            .offset(y: -5)
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
                    VStack(spacing: 2) {
                        Text(String(format: "%05.2fs", timeElapsed))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.darkActive)

                        Text("Release the button to cancel!")
                            .font(.footnote)
                            .foregroundStyle(.darkActive)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    .offset(y: 5)
                    .transition(.opacity)
                    .padding(.top)
                }

                // MARK: - DEBUG (remove before release)
                let session = WatchConnector.shared.session
                Text(session.isReachable ? "📱 Phone reachable" : "📵 Phone not reachable")
                    .font(.system(size: 9))
                    .foregroundStyle(session.isReachable ? .green : .orange)
                    .padding(.top, 4)
            }
            .frame(width: 150, height: 150)
            .navigationDestination(isPresented: $showDirection) {
                TabView {
                    DirectionView(
                        routeManager:          $routeManager,
                        emergencyService:       emergencyService,
                        showArriveConfirmation: $showArriveConfirmation,
                        showDirection:          $showDirection
                    )
                    FalseAlaramView(
                        showDirection:    $showDirection,
                        routeManager:     $routeManager,
                        emergencyService: emergencyService
                    )
                }
                .tabViewStyle(.page)
                .navigationBarBackButtonHidden()
            }
            // Arrive confirmation sits outside TabView so NavigationStack always sees it
            .navigationDestination(isPresented: $showArriveConfirmation) {
                ArriveConfirmationView(
                    showDirection:          $showDirection,
                    showArriveConfirmation: $showArriveConfirmation,
                    routeManager:           $routeManager,
                    emergencyService:       emergencyService
                )
                .navigationBarBackButtonHidden()
            }
        }
        // MARK: - Widget / Control Centre deep link
        .onOpenURL { url in
            if url.host == "sos" {
                triggerEmergency()
            }
        }
        // MARK: - Siri / AppIntent trigger
        .onChange(of: WatchAppState.shared.shouldTriggerEmergency) { _, trigger in
            if trigger {
                WatchAppState.shared.shouldTriggerEmergency = false
                triggerEmergency()
            }
        }
    }

    // MARK: - Emergency Trigger (shared by button hold, URL, and Siri)

    @MainActor
    private func triggerEmergency() {
        guard !showDirection else { return }  // already in emergency mode
        HapticManager.play(.success)
        if let coord = locationManager.coordinate {
            emergencyService.startEmergency(coordinate: coord)
        }
        showDirection = true
    }

    // MARK: - Button Hold Logic

    @MainActor
    private func startHolding() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isPressing = true
        }
        progress = 0.0
        timeElapsed = 0.0
        lastTickSecond = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            // All UI state mutations run on the main thread.
            DispatchQueue.main.async {
                self.timeElapsed += 0.01

                let currentSecond = Int(self.timeElapsed)
                if currentSecond > self.lastTickSecond && currentSecond < 3 {
                    self.lastTickSecond = currentSecond
                    HapticManager.play(.click)
                }

                if self.timeElapsed >= 3.0 {
                    self.timeElapsed = 3.0
                    self.progress = 1.0
                    self.timer?.invalidate()
                    self.triggerEmergency()
                } else {
                    self.progress = CGFloat(self.timeElapsed / 3.0)
                }
            }
        }
    }

    private func stopHolding() {
        let wasCancelled = isPressing && timeElapsed < 3.0 && timeElapsed > 0.3

        timer?.invalidate()
        timer = nil

        if wasCancelled {
            HapticManager.play(.click)
            showCancelledToast = true
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            isPressing = false
            progress = 0.0
            timeElapsed = 0.0
        }
    }
}

#Preview {
    ContentView()
}
