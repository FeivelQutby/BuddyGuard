//
//  EmergencyView.swift
//  BuddyGuard
//
//  Created by George Maximillian Theodore on 03/07/26.
//

import SwiftUI

struct EmergencyView: View {
    @State private var progress: CGFloat = 0.0
    @State private var timeElapsed: Double = 0.0
    @State private var isPressing = false
    @State private var timer: Timer?

    var body: some View {
        
        VStack (spacing: 64) {
            
            // MARK: - Header
            VStack (alignment: .leading) {
                Text("Good Evening, Maya!👋")
                    .font(.title.bold())
                    .foregroundStyle(.darker)
                Text("Stay safe, wherever you go!")
                    .font(.footnote)
                    .foregroundStyle(.dark)
                Text("**BuddyGuard** is here to help you!")
                    .font(.footnote)
                    .foregroundStyle(.dark)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(isPressing ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressing)
            
            VStack {
                // MARK: - Tooltip
                VStack(spacing: 0) {
                    Text("Hold me for 3 seconds to activate\nemergency mode")
                        .font(.footnote.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.normal)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .background(.light)
                        .cornerRadius(16)
                    
                    Image(systemName: "arrowtriangle.down.fill")
                        .foregroundStyle(.light)
                        .font(.largeTitle)
                }
                
                // MARK: - Animated Interactive Button
                Image(systemName: "teddybear.fill")
                    .font(.system(size: 192))
                    .foregroundStyle(.dark)
                    .padding(24)
                    .overlay(
                        ZStack {
                            Circle()
                                .stroke(.light, lineWidth: 20)
                            
                            Circle()
                                .trim(from: 0.0, to: progress)
                                .stroke(.dark, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
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
                
                // MARK: - Dynamic Timer Display
                if isPressing {
                    VStack(spacing: 4) {
                        Text(String(format: "%05.2fs", timeElapsed))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.normal)
                        
                        Text("Release the button to cancel!")
                            .font(.footnote)
                            .foregroundStyle(.dark)
                    }
                    .padding(.top, 24)
                    .transition(.opacity) // Smooth fade in/out
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isPressing)
            
            // MARK: - Footer
            HStack (spacing: 10) {
                Image(systemName: "headphones")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(11)
                    .background(.normalActive)
                    .cornerRadius(.infinity)
                
                VStack (alignment: .leading) {
                    Text("Please use earphones!")
                        .font(.body.bold())
                        .foregroundStyle(.darkActive)
                    Text("For navigation and emergency call when needed")
                        .font(.caption)
                        .foregroundStyle(.darkActive)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.light)
            .cornerRadius(16)
            .opacity(isPressing ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressing)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
    
    // MARK: - Animation Control Logic
    private func startHolding() {
        // Wrapped in withAnimation so the layout expands smoothly
        withAnimation(.easeInOut(duration: 0.25)) {
            isPressing = true
        }
        progress = 0.0
        timeElapsed = 0.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            timeElapsed += 0.01
            
            if timeElapsed >= 3.0 {
                timeElapsed = 3.0
                progress = 1.0
                timer?.invalidate()
                
                print("Emergency triggered!")
            } else {
                progress = CGFloat(timeElapsed / 3.0)
            }
        }
    }
    
    private func stopHolding() {
        timer?.invalidate()
        timer = nil
        
        // Wrapped in withAnimation so the layout collapses smoothly
        withAnimation(.easeInOut(duration: 0.25)) {
            isPressing = false
            progress = 0.0
            timeElapsed = 0.0
        }
    }
}

#Preview {
    EmergencyView()
}
