//
//  ActivityCard.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import SwiftUI

struct ActivityCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Circle()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(Color(.systemGray3))
                VStack(alignment: .leading) {
                    Text("John Doe")
                        .font(.body)
                    Text("Started at 10:00 PM")
                        .font(.caption2)
                }
            }
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .foregroundStyle(Color(.systemGray3))
            HStack {
                Text("GOP 9 → Indomaret Foresta")
                    .font(.caption)
                Spacer()
                Text("ETA 22.10 (1,2 km)")
                    .font(.caption)
            }
            Button(action: {}) {
                Text("Start live tracking")
                    .frame(maxWidth: .infinity)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(.purple))
                    .cornerRadius(1000)
            }
        }
        .padding(20)
        .background(Color(.blue) .opacity(0.1))
        .cornerRadius(10)
        
    }
}

#Preview {
    ActivityCard()
}
