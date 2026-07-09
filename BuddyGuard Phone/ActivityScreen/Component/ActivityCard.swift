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
                    .fill(.lightD3)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundStyle(.darkActive)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(request.name)
                        .font(.headline)
                        .foregroundStyle(.darkActive)
                    Text(request.startedAt)
                        .font(.caption)
                        .foregroundStyle(.darkActive)
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

                Text("ETA from you \(request.eta) (\(request.distance))")
                    .lineLimit(1)
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.darkActive)

            Button(action: onStartTracking) {
                Text("Start live tracking")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.normalActiveNd)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(.lightD)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview("Light") {
    ActivityCard(request: ActivityViewModel.sampleRequests[0])
        .padding(15)
}

#Preview("Dark") {
    ActivityCard(request: ActivityViewModel.sampleRequests[0])
        .padding(15)
        .preferredColorScheme(.dark)
}
