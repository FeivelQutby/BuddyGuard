//
//  FalseAlaramView.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Benedicta Joyce Sutandyo on 06/07/26.
//

import SwiftUI

struct FalseAlaramView: View {
    @State private var isYesPresented: Bool = false
    @State private var isSOSPresented: Bool = false
    @State private var isFalseAlarm: Bool = false
    @Binding var showDirection: Bool
    let routeManager = RouteManager()
    var body: some View {
        ZStack{
            VStack(){
                Text("Are you safe?").fontWeight(.semibold).padding(.bottom, 10)
    
                Button{
                    isYesPresented.toggle()
                }label:{
                    Text("Yes")
                }
                
                Button{
                    isSOSPresented.toggle()
                    WatchConnector.shared.sendUpdateStatus(.Urgent)
                }label: {
                    Text("SOS")
                }.tint(Color.red)
            }
            
        }
        .navigationDestination(isPresented: $isYesPresented){
            slide2()
                .overlay(alignment: .topTrailing){
                    overlayETA
                }.ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .overlay(alignment: .topTrailing){
            overlayETA.ignoresSafeArea()
        }
    }
        
    
    var overlayETA: some View{
        Text("ETA \(routeManager.eta ?? "...")").foregroundColor(Color.blue).padding(.top, 35).padding(.trailing, 15)
    }
    
    var backgroundGradient: some View{
        LinearGradient(
            stops:[
                .init(color: .clear, location: 0.75),
                .init(color: .black.opacity(0.3), location: 0.85),
                .init(color: .black.opacity(0.9), location: 1)
            ], startPoint: .bottom, endPoint: .top
        ).ignoresSafeArea().background(Color.accent)
    }
    
    @ViewBuilder
    func slide2() -> some View{
        ZStack{
            VStack{
                Text("Are you sure?").fontWeight(.semibold).padding(.bottom, 10)
                
                Button{
                    isFalseAlarm.toggle()
                    showDirection.toggle()
                    WatchConnector.shared.sendUpdateStatus(.Arrived)
                }label:{
                    Text("Yes")
                }

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
    }
}

#Preview {
    @State var showDirection: Bool = true
    FalseAlaramView(showDirection: $showDirection)
}
