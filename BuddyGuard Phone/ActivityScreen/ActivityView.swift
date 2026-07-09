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
