//
//  ArriveConfirmationView.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Benedicta Joyce Sutandyo on 07/07/26.
//

import SwiftUI

struct ArriveConfirmationView: View {
    @State private var isYesArrived: Bool = false
    @State private var isNoArrived: Bool = false
    @Binding var showDirection: Bool
    @Binding var showArriveConfirmation: Bool
    /// Shared routeManager for live ETA display.
    @Binding var routeManager: RouteManager
    var emergencyService: WatchEmergencyService

    var body: some View {
        ZStack {
            VStack {
                Text("Arrive yet?").fontWeight(.semibold).padding(.bottom, 10)

                HStack {
                    Button {
                        isYesArrived.toggle()
                        showDirection.toggle()
                        emergencyService.updateStatus(.Arrived)
                    } label: {
                        Text("Yes")
                    }

                    Button {
                        isNoArrived.toggle()
                        showArriveConfirmation.toggle()
                        emergencyService.updateStatus(.OnTheWay)
                    } label: {
                        Text("No")
                    }
                }
                .frame(width: 180)

                Button {
                    emergencyService.updateStatus(.Urgent)
                } label: {
                    Text("SOS")
                }
                .tint(.red)
                .frame(width: 180)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .overlay(alignment: .topTrailing) {
            overlayETA.ignoresSafeArea()
        }
    }

    var overlayETA: some View {
        Text("ETA \(routeManager.eta ?? "...")")
            .foregroundColor(Color.blue)
            .padding(.top, 35)
            .padding(.trailing, 15)
    }

    var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.75),
                .init(color: .black.opacity(0.3), location: 0.85),
                .init(color: .black.opacity(0.9), location: 1)
            ], startPoint: .bottom, endPoint: .top
        ).ignoresSafeArea().background(Color.accent)
    }
}

#Preview {
    @State var showDirection: Bool = true
    @State var showArriveConfirmation: Bool = true
    @State var routeManager: RouteManager = RouteManager()
    ArriveConfirmationView(
        showDirection:          $showDirection,
        showArriveConfirmation: $showArriveConfirmation,
        routeManager:           $routeManager,
        emergencyService:       WatchEmergencyService()
    )
}
