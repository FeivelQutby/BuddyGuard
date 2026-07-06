import SwiftUI
import MapKit

struct BottomSheetView: View{
    /// Only needed for `.emergencyContact` — the friend being tracked.
    let request: ActivityRequest?
    let role: MapRole
    @Binding var sheetDetent: PresentationDetent
    @Binding var routeManager: RouteManager
    var onSOS: () -> Void = {}
    var onImSafe: () -> Void = {}
    
    var body: some View{
        if sheetDetent == .height(80){
            VStack{
                Text("To \(routeManager.safePlaceName ?? "Unknown location")").font(.system(size: 15, weight: .semibold))
                Text("ETA \(routeManager.eta ?? "...") (\(routeManager.distance ?? "...") km)").font(.system(size: 12))
            }.task{
                let info = await routeManager.getSafePlaceInfo()
                routeManager.safePlaceName = info.name
            }
        }else if sheetDetent == .height(350){
            switch role {
            case .emergencyContact:
                if let request {
                    EmergencyContactDetail(request: request, routeManager: $routeManager)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            Text("\(request.name)'s Activity").font(.largeTitle).fontWeight(.bold).frame(alignment: .topLeading)
            
            HStack{
                VStack(alignment: .leading){
                    Text("\(request.name)'s status").font(.footnote)
                    RoundedRectangle(cornerRadius: 10).fill(request.state.fillColor).stroke(request.state.strokeColor, lineWidth: 2).frame(height: 50).overlay(
                        Text(request.state.label).font(.title3).fontWeight(.bold).foregroundColor(.black).frame(maxWidth: .infinity,alignment: .leading).padding()
                    )
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading){
                    Text("From").font(.footnote)
                    RoundedRectangle(cornerRadius: 10).fill(Color.clear).frame(height: 50).overlay(
                        Text("\(routeManager.sourcePlaceName ?? "Unknown location")").font(.title3).fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity,alignment: .leading)
                    )
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.task{
                routeManager.sourcePlaceName = await routeManager.getSourcePlaceName(from: request.coordinate)
            }
            
            HStack{
                VStack(alignment: .leading){
                    Text("\(routeManager.safePlaceName ?? "Unknown location")").font(.body).fontWeight(.bold)
                    Text("\(routeManager.safePlaceAddress ?? "Unknown location")").font(.footnote)
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading){
                    Text("ETA").font(.footnote)
                    Text("\(routeManager.eta ?? "...") (\(routeManager.distance ?? "...") km)").font(.title3).fontWeight(.bold)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.task{
                let info = await routeManager.getSafePlaceInfo()
                routeManager.safePlaceName = info.name
                routeManager.safePlaceAddress = info.address
            }
        }.padding()
            .offset(y: -20)
        Button{
            // TODO: notify request.name that the contact is on the way, once the notif layer exists.
        }label:{
            Text("I'm on my way").foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: 50)
        }.buttonStyle(.borderedProminent).tint(.normalActive).padding()
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
            Text("Heading to Safety").font(.largeTitle).fontWeight(.bold).frame(alignment: .topLeading)
            
            VStack(alignment: .leading){
                Text("Destination").font(.footnote)
                Text("\(routeManager.safePlaceName ?? "Unknown location")").font(.title3).fontWeight(.bold)
                Text("\(routeManager.safePlaceAddress ?? "Unknown location")").font(.footnote)
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading){
                Text("ETA").font(.footnote)
                Text("\(routeManager.eta ?? "...") (\(routeManager.distance ?? "...") km)").font(.title3).fontWeight(.bold)
            }.frame(maxWidth: .infinity, alignment: .leading)
                .task{
                    let info = await routeManager.getSafePlaceInfo()
                    routeManager.safePlaceName = info.name
                    routeManager.safePlaceAddress = info.address
                }
            
            HStack(spacing: 12){
                Button(action: onSOS){
                    Text("SOS").foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: 50)
                }.buttonStyle(.borderedProminent).tint(.statusRed)
                
                Button(action: onImSafe){
                    Text("I'm Safe").foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: 50)
                }.buttonStyle(.borderedProminent).tint(.normalActive)
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

#Preview("Active User") {
    @Previewable @State var sheetDetent: PresentationDetent = .height(350)
    @Previewable @State var routeManager: RouteManager = RouteManager()
    BottomSheetView(request: nil, role: .activeUser, sheetDetent: $sheetDetent, routeManager: $routeManager)
}
