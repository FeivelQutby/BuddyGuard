import SwiftUI
import MapKit

struct BottomSheetCard: View{
    let request: ActivityRequest?
    let role: MapRole
    @Binding var sheetDetent: PresentationDetent
    @Binding var routeManager: RouteManager
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
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { sheetDetent = .height(350) }
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
