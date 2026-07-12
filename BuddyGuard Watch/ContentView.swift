//
//  ContentView.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Feivel Qutby on 26/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var showDirection: Bool = false
    @State private var isPressing: Bool = false
    @State private var progress: CGFloat = 0.0
    @State private var timeElapsed: Double = 0.0
    @State private var lastTickSecond: Int = 0
    @State private var timer: Timer?
    @State private var locationManager = LocationManager()
    @State private var routeManager = RouteManager()
    @State private var showCancelledToast = false
    @State private var showEndedToast = false
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 0){
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
                    .transition(.opacity) // Smooth fade in/out
                    .padding(.top)
                }
                
            }
            .frame(width: 150, height: 150)
            .navigationDestination(isPresented: $showDirection){
                TabView{
                    DirectionView(showDirection: $showDirection)
                    FalseAlaramView(showDirection: $showDirection)
                }
                .tabViewStyle(.page)
                .navigationBarBackButtonHidden()
            }
        }
        .onOpenURL{
            url in if url.host == "sos"{
                showDirection = true
            }
        }
    }
    
    @MainActor
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
                HapticManager.play(.click)
            }

            if timeElapsed >= 3.0 {
                timeElapsed = 3.0
                progress = 1.0
                timer?.invalidate()

                HapticManager.play(.success)
                showDirection = true

                if let coord = locationManager.coordinate {
                    WatchConnector.shared.sendStartSession(with: coord)
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
