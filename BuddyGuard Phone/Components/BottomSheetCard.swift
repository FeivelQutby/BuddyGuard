import SwiftUI
import MapKit

struct BottomSheetCard: View{
    /// Only needed for `.emergencyContact` — the friend being tracked.
    let request: ActivityRequest?
    let role: MapRole
    @Binding var sheetDetent: PresentationDetent
    @Binding var routeManager: RouteManager
    /// Live status from the Firestore session listener
    var trackedUserStatus: UserState = .OnTheWay
    var notifiedContacts: [EmergencyContact] = []
    var onSOS: () -> Void = {}
    var onImSafe: () -> Void = {}
    var onImOnMyWay: () -> Void = {}
    
    var body: some View{
        if sheetDetent == .height(80){
            VStack{
                Text("To \(routeManager.safePlaceName ?? "Finding location...")")
                    .font(.system(size: 15, weight: .semibold))
                Text("ETA \(routeManager.eta ?? "...") (\(routeManager.distance ?? "...") km)")
                    .font(.system(size: 12))
            }
        }else if sheetDetent == .height(350){
            switch role {
            case .emergencyContact:
                if let request {
                    EmergencyContactDetail(
                        request: request,
                        routeManager: $routeManager,
                        liveStatus: trackedUserStatus,
                        onImOnMyWay: onImOnMyWay
                    )
                }
            case .activeUser:
                ActiveUserDetail(routeManager: $routeManager, contacts: notifiedContacts, onSOS: onSOS, onImSafe: onImSafe)
            }
        }
    }
}

/// What the friend/contact sees while tracking someone else: their status, where
/// they started from, and their ETA to the safe place.
private struct EmergencyContactDetail: View {
    let request: ActivityRequest
    @Binding var routeManager: RouteManager
    /// Live status from the Firestore session listener — updates in real-time
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

/// What the at-risk person sees on their own live-tracking screen: where they're
/// headed, their ETA, and the two actions that change their own status.
private struct ActiveUserDetail: View {
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

#Preview("Emergency Contact") {
    @Previewable @State var sheetDetent: PresentationDetent = .height(350)
    @Previewable @State var routeManager: RouteManager = RouteManager()
    BottomSheetCard(request: ActivityViewModel.sampleRequests[0], role: .emergencyContact, sheetDetent: $sheetDetent, routeManager: $routeManager)
}

#Preview("Emergency Contact Dark") {
    @Previewable @State var sheetDetent: PresentationDetent = .height(350)
    @Previewable @State var routeManager: RouteManager = RouteManager()
    BottomSheetCard(request: ActivityViewModel.sampleRequests[0], role: .emergencyContact, sheetDetent: $sheetDetent, routeManager: $routeManager)
        .preferredColorScheme(ColorScheme.dark)
}

#Preview("Active User") {
    @Previewable @State var sheetDetent: PresentationDetent = .height(350)
    @Previewable @State var routeManager: RouteManager = RouteManager()
    BottomSheetCard(request: nil, role: .activeUser, sheetDetent: $sheetDetent, routeManager: $routeManager)
}

#Preview("Active User Dark") {
    @Previewable @State var sheetDetent: PresentationDetent = .height(350)
    @Previewable @State var routeManager: RouteManager = RouteManager()
    BottomSheetCard(request: nil, role: .activeUser, sheetDetent: $sheetDetent, routeManager: $routeManager)
        .preferredColorScheme(ColorScheme.dark)
}
