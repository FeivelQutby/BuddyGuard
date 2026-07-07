import SwiftUI
import MapKit

struct BottomSheetView: View{
    /// Only needed for `.emergencyContact` — the friend being tracked.
    let request: ActivityRequest?
    let role: MapRole
    @Binding var sheetDetent: PresentationDetent
    @Binding var routeManager: RouteManager
    /// Live status from the Firestore session listener
    var trackedUserStatus: UserState = .OnTheWay
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
                ActiveUserDetail(routeManager: $routeManager, onSOS: onSOS, onImSafe: onImSafe)
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
        VStack(alignment: .leading, spacing: 20){
            Text("\(request.name)'s Activity").font(.largeTitle).fontWeight(.bold).frame(alignment: .topLeading).foregroundStyle(.darkActive)
            
            HStack{
                VStack(alignment: .leading){
                    Text("\(request.name)'s status").font(.footnote).foregroundStyle(.darkActive)
                    RoundedRectangle(cornerRadius: 10).fill(liveStatus.fillColor).stroke(liveStatus.strokeColor, lineWidth: 2).frame(height: 50).overlay(
                        Text(liveStatus.label).font(.title3).fontWeight(.bold).foregroundColor(.black).frame(maxWidth: .infinity,alignment: .leading).padding()
                    )
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading){
                    Text("From").font(.footnote)
                        .foregroundStyle(.darkActive)
                    RoundedRectangle(cornerRadius: 10).fill(Color.clear).frame(height: 50).overlay(
                        Text("\(routeManager.sourcePlaceName ?? "Unknown location")").font(.title3).fontWeight(.bold).frame(maxWidth: .infinity,alignment: .leading)
                            .foregroundStyle(.darkActive)
                    )
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.task{
                routeManager.sourcePlaceName = await routeManager.getSourcePlaceName(from: request.coordinate)
            }
            
            HStack{
                VStack(alignment: .leading){
                    Text("\(routeManager.safePlaceName ?? "Finding location...")").font(.body).fontWeight(.bold)
                        .foregroundStyle(.darkActive)
                    Text("\(routeManager.safePlaceAddress ?? "...")").font(.footnote)
                        .foregroundStyle(.darkActive)
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading){
                    Text("ETA").font(.footnote)
                        .foregroundStyle(.darkActive)
                    Text("\(routeManager.eta ?? "...") (\(routeManager.distance ?? "...") km)").font(.title3).fontWeight(.bold)
                        .foregroundStyle(.darkActive)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding()
            .offset(y: -20)
        
        // "I'm on my way" — navigates contact to the SAFE DESTINATION, not the friend
        Button{
            guard !isNavigating else { return }
            isNavigating = true
            onImOnMyWay()
        }label:{
            HStack(spacing: 8) {
                if isNavigating {
                    Image(systemName: "figure.walk")
                    Text("I'm going to Safe Place")
                } else {
                    Image(systemName: "car.fill")
                    Text("I'm on my way")
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(isNavigating ? .green : .normalActiveNd)
        .padding()
    }
}

/// What the at-risk person sees on their own live-tracking screen: where they're
/// headed, their ETA, and the two actions that change their own status.
private struct ActiveUserDetail: View {
    @Binding var routeManager: RouteManager
    var onSOS: () -> Void
    var onImSafe: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            Text("Heading to Safety")
                .foregroundStyle(.darkActive).font(.largeTitle).fontWeight(.bold).frame(alignment: .topLeading)
            
            VStack(alignment: .leading){
                Text("Destination").font(.footnote)
                    .foregroundStyle(.darkActive)
                Text("\(routeManager.safePlaceName ?? "Finding location...")").font(.title3).fontWeight(.bold).foregroundStyle(.darkActive)
                Text("\(routeManager.safePlaceAddress ?? "...")").font(.footnote).foregroundStyle(.darkActive)
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading){
                Text("ETA").font(.footnote)
                    .foregroundStyle(.darkActive)
                Text("\(routeManager.eta ?? "...") (\(routeManager.distance ?? "...") km)").font(.title3).fontWeight(.bold)
                    .foregroundStyle(.darkActive)
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12){
                Button(action: onSOS){
                    Text("SOS").foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: 50).fontWeight(.bold)
                }.buttonStyle(.borderedProminent).tint(.red)
                
                Button(action: onImSafe){
                    Text("I'm Safe").foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: 50).fontWeight(.bold)
                }.buttonStyle(.borderedProminent).tint(.normalActiveNd)
            }
        }.padding()
            .offset(y: -20)
    }
}

#Preview("Emergency Contact") {
    @Previewable @State var sheetDetent: PresentationDetent = .height(350)
    @Previewable @State var routeManager: RouteManager = RouteManager()
    BottomSheetView(request: ActivityViewModel.sampleRequests[0], role: .emergencyContact, sheetDetent: $sheetDetent, routeManager: $routeManager)
}

#Preview("Emergency Contact Dark") {
    @Previewable @State var sheetDetent: PresentationDetent = .height(350)
    @Previewable @State var routeManager: RouteManager = RouteManager()
    BottomSheetView(request: ActivityViewModel.sampleRequests[0], role: .emergencyContact, sheetDetent: $sheetDetent, routeManager: $routeManager)
        .preferredColorScheme(ColorScheme.dark)
}

#Preview("Active User") {
    @Previewable @State var sheetDetent: PresentationDetent = .height(350)
    @Previewable @State var routeManager: RouteManager = RouteManager()
    BottomSheetView(request: nil, role: .activeUser, sheetDetent: $sheetDetent, routeManager: $routeManager)
}

#Preview("Active User Dark") {
    @Previewable @State var sheetDetent: PresentationDetent = .height(350)
    @Previewable @State var routeManager: RouteManager = RouteManager()
    BottomSheetView(request: nil, role: .activeUser, sheetDetent: $sheetDetent, routeManager: $routeManager)
        .preferredColorScheme(ColorScheme.dark)
}
