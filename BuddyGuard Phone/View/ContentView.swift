//
//  ContentView.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 26/06/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(DeepLinkRouter.self) private var deepLinkRouter
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Emergency", systemImage: "exclamationmark.shield.fill", value: 0) {
                EmergencyView()
            }
            Tab("Activity", systemImage: "text.document.fill", value: 1) {
                ActivityView()
            }
            Tab("Profile", systemImage: "person.2.fill", value: 2) {
                ProfileView()
            }
        }
        .tint(.normalActiveNd)
        .onChange(of: deepLinkRouter.selectedTab) { _, newTab in
            selectedTab = newTab
        }
    }
}

#Preview("Light Mode") {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
    .preferredColorScheme(.dark)
}
