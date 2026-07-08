//
//  SwiftUIView.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Benedicta Joyce Sutandyo on 07/07/26.
//

import SwiftUI

struct SwiftUIView: View {
    @State private var isYesArrived: Bool = false
    @State private var isNoArrived: Bool = false
    var body: some View {
        ZStack{
            VStack{
                Text("Arrive yet?").fontWeight(.semibold).padding(.bottom, 10)
                
                HStack{
                    Button{
                        isYesArrived.toggle()
                    }label:{
                        Text("Yes")
                    }
                    
                    Button{
                        isNoArrived.toggle()
                    }label: {
                        Text("No")
                    }
                }
                .frame(width: 180)
                
                Button{
                    
                }label:{
                    Text("SOS")
                }.tint(.red).frame(width: 180)
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .overlay(alignment: .topTrailing){
            overlayETA.ignoresSafeArea()
        }
    }
    
    var overlayETA: some View{
        Text("ETA 22.00").foregroundColor(Color.blue).padding(.top, 35).padding(.trailing, 15)
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
}

#Preview {
    SwiftUIView()
}
