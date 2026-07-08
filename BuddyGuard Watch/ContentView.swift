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
            VStack(spacing: 20){
                Image(systemName: "headphones")
                    .font(.system(size: 50)).tint(.white)
                VStack{
                    Text("Use Earphone").font(.system(size: 20, weight: .semibold))
                    Text("For Navigation and emergency call").font(.system(size: 16)).fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.center)
                }
                
                Button{
                    showDirection = true
                }label:{
                    Text("OK")
                }
            }
            .padding()
            .navigationDestination(isPresented: $showDirection){
                TabView{
                    DirectionView()
                    FalseAlaramView()
                }
                .tabViewStyle(.page)
                .navigationBarBackButtonHidden()
            }
        }
    }
}

#Preview {
    ContentView()
}
