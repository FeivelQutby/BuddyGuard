//
//  Activity.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import SwiftUI

struct ActivityView: View {
    var body: some View {
        VStack {
            Circle()
                .foregroundStyle(.gray)
                .opacity(0.5)
            Text("No Active Request")
            Text("There's no active emergency request.")
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works?")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.16, green: 0.13, blue: 0.42))

                Text("• Your friend or family member will send you a help request when they need you.\n• You will receive the notification and real-time location of them.")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.16, green: 0.13, blue: 0.42))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.92, green: 0.91, blue: 1.0))
            )
        }
        .padding(40)
        
    }
}

#Preview {
    ActivityView()
}
