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
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works?")
                    .font(.title3.weight(Font.Weight.semibold))
                    .foregroundStyle(.darkActive)
                Text("• Your friend or family member will send you a help request when they need you.\n• You will receive the notification and real-time location of them.")
                    .font(Font.system(.footnote))
                    .foregroundStyle(.darkActive)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.lightD)
            )
        }
        .padding(16)
    }
}
