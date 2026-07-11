import SwiftUI

struct ActivityView: View {
    @Environment(DeepLinkRouter.self) private var deepLinkRouter
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
        // ── Deep Link: notification tap brings us here ────────────────────
        // Triggered when the Activity tab becomes visible with a pending session.
        .onAppear {
            consumePendingDeepLink()
        }
        // Triggered on cold launch: data may not be loaded yet when onAppear fires,
        // so we also watch for the requests list to populate.
        .onChange(of: viewModel.requests) { _, _ in
            consumePendingDeepLink()
        }
        .toast(isPresented: $showAlertToast, icon: "exclamationmark.triangle.fill", message: "\(alertName) needs help! Tap to view location.", tint: .red, duration: 4.0)
    }
    
    // ── Helpers ───────────────────────────────────────────────────────────
    
    /// Finds the request matching the pending session ID and opens it.
    /// Safe to call multiple times — clears the pending ID after consuming it.
    private func consumePendingDeepLink() {
        guard let sessionId = deepLinkRouter.pendingSessionId else { return }
        guard let match = viewModel.requests.first(where: { $0.sessionId == sessionId }) else {
            // Data not ready yet — onChange(of: viewModel.requests) will retry.
            return
        }
        deepLinkRouter.pendingSessionId = nil
        viewModel.startTracking(match)
    }
}

#Preview("Active Requests") {
    ActivityView(viewModel: ActivityViewModel(requests: ActivityViewModel.sampleRequests))
        .preferredColorScheme(.light)
        .environment(DeepLinkRouter.shared)
}

#Preview("Active Requests Dark") {
    ActivityView(viewModel: ActivityViewModel(requests: ActivityViewModel.sampleRequests))
        .preferredColorScheme(.dark)
        .environment(DeepLinkRouter.shared)
}

#Preview("Empty State") {
    ActivityView(viewModel: ActivityViewModel(requests: []))
        .environment(DeepLinkRouter.shared)
}
#Preview("Empty State Dark") {
    ActivityView(viewModel: ActivityViewModel(requests: []))
        .preferredColorScheme(.dark)
        .environment(DeepLinkRouter.shared)
}
