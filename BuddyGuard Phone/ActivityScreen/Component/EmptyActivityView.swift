import SwiftUI

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("mascot")
                .background(
                    Image("effect")
                )
            Text("No Active Request")
                .font(.title.weight(.bold))
                .foregroundStyle(.darkActive)
            Text("There's no active request.")
                .foregroundStyle(.darkHover)
                .font(.system(.body))
            Divider()
                .opacity(0)
                .frame(height:100)
            VStack(alignment: .leading, spacing: 4) {
                Text("How it works?")
                    .font(.body.weight(Font.Weight.semibold))
                    .foregroundStyle(.darkActive)
                
                VStack{
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                        Text("Your friend or family member will send you a help request when they need you.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.darkActive)
                    
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                        Text("You will receive the notification and real-time location of them.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.darkActive)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.lightD)
            )
        }
        .padding(16)
    }
}

#Preview("Light") {
    EmptyActivityView()
}

#Preview("Dark") {
    EmptyActivityView()
        .preferredColorScheme(.dark)
}

