import SwiftUI
import MapKit

struct BottomSheetView: View{
    @Binding var sheetDetent: PresentationDetent
    @Binding var routeManager: RouteManager
    
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
            VStack(alignment: .leading, spacing: 20){
                Text("\(DummyData.user1.nama)'s Activity").font(.largeTitle).fontWeight(.bold).frame(alignment: .topLeading)
                
                HStack{
                    VStack(alignment: .leading){
                        Text("\(DummyData.user1.nama)'s status").font(.footnote)
                        RoundedRectangle(cornerRadius: 10).fill(getUserStateColor(from: DummyData.user1.state)).stroke(getUserStateStrokeColor(from: DummyData.user1.state), lineWidth: 2).frame(height: 50).overlay(
                            Text(getUserState(from: DummyData.user1.state)).font(.title3).fontWeight(.bold).foregroundColor(.black).frame(maxWidth: .infinity,alignment: .leading).padding()
                        )
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading){
                        Text("From").font(.footnote)
                        RoundedRectangle(cornerRadius: 10).fill(Color.clear).frame(height: 50).overlay(
                            Text("\(routeManager.sourcePlaceName ?? "Unknown location")").font(.title3).fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity,alignment: .leading)
                        )
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.task{
                    routeManager.sourcePlaceName = await routeManager.getSourcePlaceName()
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
                
            }label:{
                Text("I'm on my way").foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: 50)
            }.buttonStyle(.borderedProminent).tint(.normalActive).padding()
        }
    }
}

#Preview {
    @State var sheetDetent: PresentationDetent = .height(80)
    @State var routeManager: RouteManager = RouteManager()
    BottomSheetView(sheetDetent: $sheetDetent, routeManager: $routeManager)
}
