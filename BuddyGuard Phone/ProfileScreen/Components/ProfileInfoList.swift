import SwiftUI
import FirebaseAuth

struct ProfileInfoList: View {
    let authManager: AuthManager

    var body: some View {
        VStack(spacing: 0) {
            ProfileInfoCard(icon: "person.fill", title: "Display Name", value: authManager.displayName, isEditable: true)
            Divider().background(.gray)
            ProfileInfoCard(icon: "envelope.fill", title: "Email", value: authManager.email)
            Divider().background(.gray)
            ProfileInfoCard(
                icon: authManager.currentUser?.providerData.first?.providerID == "google.com" ? "g.circle.fill" : "applelogo",
                title: "Sign-in Method",
                value: authManager.currentUser?.providerData.first?.providerID == "google.com" ? "Google" : "Apple"
            )
        }
    }
}

#Preview("Light") {
    ProfileInfoList(authManager: AuthManager())
        .environment(AuthManager())
        .padding(16)
}

#Preview("Dark") {
    ProfileInfoList(authManager: AuthManager())
        .environment(AuthManager())
        .padding(16)
        .preferredColorScheme(.dark)
}
