//
//  TopSheetCard.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 07/07/26.
//

import SwiftUI

struct TopSheetCard: View {
    var body: some View {
        VStack{
            HStack{
                Image(systemName:"arrow.turn.up.right")
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading){
                    Text("200m").font(Font.largeTitle.bold())
                    Text("Turn Right").fontWeight(.semibold)
                }
                Spacer()
            }
            .padding(8) 
            Divider()
            
        }
        .padding(15)
        .background(.gray.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview("Light") {
    TopSheetCard()
        .padding(15)
}

#Preview("Dark") {
    TopSheetCard()
        .padding(15)
        .preferredColorScheme(.dark)
}
