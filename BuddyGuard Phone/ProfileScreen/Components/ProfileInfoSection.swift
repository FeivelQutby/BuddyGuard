import SwiftUI
import FirebaseAuth

struct ProfileInfoSection: View {
    let authManager: AuthManager

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color(.systemGray3))

            ProfileInfoRow(icon: "person.fill", title: "Display Name", value: authManager.displayName, isEditable: true)
            Divider().background(Color(.systemGray3))
            ProfileInfoRow(icon: "envelope.fill", title: "Email", value: authManager.email)
            Divider().background(Color(.systemGray3))
            ProfileInfoRow(
                icon: authManager.currentUser?.providerData.first?.providerID == "google.com" ? "g.circle.fill" : "applelogo",
                title: "Sign-in Method",
                value: authManager.currentUser?.providerData.first?.providerID == "google.com" ? "Google" : "Apple"
            )
        }
    }
}
