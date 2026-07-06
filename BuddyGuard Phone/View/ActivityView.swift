//
//  Activity.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import SwiftUI

struct ActivityView: View {
    @State private var viewModel: ActivityViewModel

    init(viewModel: ActivityViewModel = ActivityViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.requests.isEmpty {
                EmptyActivityView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Active Requests")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.darkActive)

                        ForEach(viewModel.requests) { request in
                            ActivityCard(request: request) {
                                viewModel.startTracking(request)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .fullScreenCover(item: $viewModel.activeRequest) { request in
            MapView(request: request)
        }
    }
}

private struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .foregroundStyle(.gray)
                .overlay(
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                )
                .opacity(0.5)
                .frame(width: 240, height: 240)
            Text("No Active Request")
                .font(.title.weight(.bold))
                .foregroundStyle(.darkActive)
            Text("There's no active request.")
                .foregroundStyle(.darkHover)
                .font(.system(.caption))
            Divider()
                .opacity(0)
                .frame(height:20)
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works?")
                    .font(.body.weight(Font.Weight.semibold))
                    .foregroundStyle(.darkActiveNd)
                Text("• Your friend or family member will send you a help request when they need you.\n• You will receive the notification and real-time location of them.")
                    .font(Font.system(.caption))
                    .foregroundStyle(.darkActiveNd)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.lightActive) // nd
            )
        }
        .padding(16)
    }
}

#Preview("Active Requests") {
    ActivityView(viewModel: ActivityViewModel(requests: ActivityViewModel.sampleRequests))
}

#Preview("Active Requests Dark") {
    ActivityView(viewModel: ActivityViewModel(requests: ActivityViewModel.sampleRequests))
        .preferredColorScheme(.dark)
}


#Preview("Empty State") {
    ActivityView(viewModel: ActivityViewModel(requests: []))
}
#Preview("Empty State Dark") {
    ActivityView(viewModel: ActivityViewModel(requests: []))
        .preferredColorScheme(.dark)
}
