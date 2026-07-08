//
//  Activity.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import SwiftUI

struct ActivityView: View {
    @State private var viewModel: ActivityViewModel
    @State private var showAlertToast = false
    @State private var alertName = ""

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
            MapView(request: request, role: .emergencyContact)
        }
        .onChange(of: viewModel.requests.count) { oldCount, newCount in
            if newCount > oldCount, let newest = viewModel.requests.last {
                HapticManager.notification(.warning)
                alertName = newest.name
                showAlertToast = true
            }
        }
        .toast(isPresented: $showAlertToast, icon: "exclamationmark.triangle.fill", message: "\(alertName) needs help! Tap to view location.", tint: .red, duration: 4.0)
    }
}

private struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("mascot")
                .background(
                    Image("effect")
                )
            Text("No Active Request")
                .font(.title.weight(.bold))
                .foregroundStyle(.darkActive)
            Text("There's no active request.")
                .foregroundStyle(.darkHover)
                .font(.system(.body))
            Divider()
                .opacity(0)
                .frame(height:100)
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works?")
                    .font(.title3.weight(Font.Weight.semibold))
                    .foregroundStyle(.darkActive)
                Text("• Your friend or family member will send you a help request when they need you.\n• You will receive the notification and real-time location of them.")
                    .font(Font.system(.footnote))
                    .foregroundStyle(.darkActive)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.lightD)
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
