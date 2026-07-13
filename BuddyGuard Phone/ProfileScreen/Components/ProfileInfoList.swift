import SwiftUI
import FirebaseAuth

struct ProfileInfoList: View {
    let authManager: AuthManager

    @State private var showSignOutConfirmation = false

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
            Divider().background(.gray)

            Button {
                showSignOutConfirmation = true
            } label: {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.red)
                        )
                    Text("Sign Out")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.red)
                }
                .padding(.vertical, 10)
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
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
