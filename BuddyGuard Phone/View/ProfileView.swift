//
//  ProfileView.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import SwiftUI

struct ProfileView: View {
    @State private var segment = 0
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .foregroundStyle(.gray)
                .opacity(0.5)
                .frame(width: 150, height: 150)
            Text("Maya")
                .font(.title3.weight(.semibold))
            
            Picker("What is your favorite color?", selection: $segment) {
                Text("􀉪Profile").tag(0)
                Text("􀝋Contact").tag(1)
            }
            .pickerStyle(.segmented)
            HStack{
                Text("Profile Information")
                Spacer()
                Text("􀈊Edit").foregroundColor(.blue)
            }
        }
        .padding(16)
    }
}

#Preview {
    ProfileView()
}
