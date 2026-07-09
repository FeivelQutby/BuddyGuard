import SwiftUI
import MapKit

struct EmergencyContactDetail: View {
    let request: ActivityRequest
    @Binding var routeManager: RouteManager
    var liveStatus: UserState
    var onImOnMyWay: () -> Void

    @State private var isNavigating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(request.name)'s Activity")
                .font(.title2.weight(.bold))
                .foregroundStyle(.darkActive)
                .padding(.bottom, 16)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(request.name)'s status")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Image(systemName: liveStatus.iconName)
                            .font(.body.weight(.bold))
                            .foregroundStyle(liveStatus.fillColor)
                        Text(liveStatus.label)
                            .font(.body.weight(.bold))
                            .foregroundStyle(liveStatus.fillColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ETA")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("\(routeManager.eta ?? "...") (\(routeManager.distance ?? "...") km)")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.darkActive)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 16)
            .task {
                routeManager.sourcePlaceName = await routeManager.getSourcePlaceName(from: request.coordinate)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("From")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(routeManager.sourcePlaceName ?? "Unknown location")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.darkActive)
            }
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("To")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(routeManager.safePlaceName ?? "Finding Location...")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.darkActive)
                Text(routeManager.safePlaceAddress ?? "...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                guard !isNavigating else { return }
                isNavigating = true
                HapticManager.impact(.medium)
                onImOnMyWay()
            } label: {
                HStack(spacing: 8) {
                    if isNavigating {
                        Image(systemName: "figure.walk")
                        Text("I'm going to Safe Place")
                    } else {
                        Image(systemName: "car.fill")
                        Text("I'm on my way")
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(isNavigating ? .green : .normalActiveNd)
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
