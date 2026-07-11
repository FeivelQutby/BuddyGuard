import SwiftUI
import MapKit

struct ActiveUserDetail: View {
    @Binding var routeManager: RouteManager
    var contacts: [EmergencyContact]
    var onSOS: () -> Void
    var onImSafe: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Heading to safety")
                .font(.title2.weight(.bold))
                .foregroundStyle(.darkActive)
                .padding(.bottom, 16)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emergency contact")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack(spacing: -8) {
                        ForEach(contacts.prefix(5)) { contact in
                            Circle()
                                .fill(.normalActiveNd)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(contact.displayName.prefix(1).uppercased())
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                )
                                .overlay(
                                    Circle().stroke(.white, lineWidth: 2)
                                )
                        }
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

            VStack(alignment: .leading, spacing: 4) {
                Text("From")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(routeManager.sourcePlaceName ?? "Current Location")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.darkActive)
            }
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("To nearest safe place")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(routeManager.safePlaceName ?? "Finding location...")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.darkActive)
                Text(routeManager.safePlaceAddress ?? "...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    HapticManager.notification(.error)
                    onSOS()
                } label: {
                    Text("SOS")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button {
                    HapticManager.notification(.success)
                    onImSafe()
                } label: {
                    Text("I'm safe")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.normalActiveNd)
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

