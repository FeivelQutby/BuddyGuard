//
//  ActivityCard.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import MapKit
import SwiftUI

struct ActivityCard: View {
    let request: ActivityRequest
    var onStartTracking: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Circle()
                    .fill(.white)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(request.name)
                        .font(.headline)
                        .foregroundStyle(.black)
                    Text(request.startedAt)
                        .font(.caption)
                        .foregroundStyle(.black)
                }
            }

            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: request.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                    )
                ),
                interactionModes: []
            )
            .frame(height: 136)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .mapControlVisibility(.hidden)

            HStack(spacing: 8) {
                Text(request.route)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("\(request.eta) (\(request.distance))")
                    .lineLimit(1)
            }
            .font(.caption)
            .foregroundStyle(.black)

            Button(action: onStartTracking) {
                Text("Start live tracking")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.normalActive)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(.light)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ActivityCard(request: ActivityViewModel.sampleRequests[0])
        .padding()
}
