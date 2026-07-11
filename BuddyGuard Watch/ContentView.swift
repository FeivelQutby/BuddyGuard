//
//  ContentView.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Feivel Qutby on 26/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var showDirection: Bool = false
    var body: some View {
        NavigationStack{
            VStack(spacing: 10){
                Image("mascot").resizable().scaledToFit().frame(width: 85, height: 85).tint(.white).padding(0)
                
                VStack{
                    Text("BuddyGuard").font(.system(size: 20, weight: .semibold))
                    Text("For Navigation and emergency call").font(.system(size: 16)).fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.center)
                }.padding(0)
                
                Button{
                    showDirection = true
                }label:{
                    Text("OK")
                }
            }
            .padding(.bottom, 15)
            .navigationDestination(isPresented: $showDirection){
                TabView{
                    DirectionView(showDirection: $showDirection)
                    FalseAlaramView(showDirection: $showDirection)
                }
                .tabViewStyle(.page)
                .navigationBarBackButtonHidden()
            }
        }
        .onOpenURL{
            url in if url.host == "sos"{
                showDirection = true
            }
        }
    }
}

#Preview {
    ContentView()
}
