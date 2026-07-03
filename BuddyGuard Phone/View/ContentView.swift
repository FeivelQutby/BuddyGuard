//
//  ContentView.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 26/06/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Emergency", systemImage: "exclamationmark.shield.fill") {
            }
            Tab("Activity", systemImage: "text.document.fill") {
                ActivityView()
            }
            Tab("Profile", systemImage: "person.2.fill") {
                ProfileView()
            }
        }
    }
}

#Preview {
    ContentView()
}
