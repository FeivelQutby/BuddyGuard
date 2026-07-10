import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @Environment(AuthManager.self) private var authManager
    @Environment(DeepLinkRouter.self) private var deepLinkRouter

    @State private var showAddContactSheet = false
    @State private var contactManager = EmergencyContactManager()

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack(alignment: .bottom) {
            VStack(spacing: 8) {
                Circle()
                    .foregroundStyle(.normalActiveNd)
                    .overlay(
                        Text(authManager.displayName.prefix(1).uppercased())
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(.light)
                    )
                    .frame(width: 110, height: 110)

                VStack(spacing: 4) {
                    Text(authManager.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.darkActive)
                    Text(authManager.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Picker("Profile Section", selection: $viewModel.selectedSegment) {
                    ForEach(ProfileSegment.allCases, id: \.self) { segment in
                        Label(segment.title, systemImage: segment.systemImage)
                            .tag(segment)
                            .foregroundStyle(.darkActive)
                    }
                }
                .pickerStyle(.segmented)
                .tint(.dark)
                .padding(.top, 8)

                HStack(alignment: .firstTextBaseline) {
                    Text(viewModel.sectionTitle)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.darkActive)

                    Spacer()
                }
                .padding(.top, 20)

                switch viewModel.selectedSegment {
                case .profile:
                    ProfileInfoList(authManager: authManager)
                        .padding(.top, 12)
                case .contact:
                    EmergencyContactList(
                        contacts: viewModel.emergencyContacts, contactManager: contactManager
                    )
                    .padding(.top, 12)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if viewModel.selectedSegment == .contact {
                Button {
                    showAddContactSheet = true
                } label: {
                    Text("Add Emergency Contact")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.normalActiveNd)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 28)

            } else if viewModel.selectedSegment == .profile {
                Button {
                    authManager.signOut()
                } label: {
                    Text("Log Out")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showAddContactSheet) {
            AddContactSheet()
                .presentationDetents([.medium,.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            contactManager.startListeningToInbox()
        }
        .onChange(of: deepLinkRouter.showContactSection) { _, show in
            if show {
                viewModel.selectedSegment = .contact
                deepLinkRouter.showContactSection = false
            }
        }
    }
}

#Preview("Light Mode") {
    ProfileView()
        .environment(AuthManager())
        .environment(DeepLinkRouter.shared)
}

#Preview("Dark Mode") {
    ProfileView()
        .preferredColorScheme(.dark)
        .environment(AuthManager())
        .environment(DeepLinkRouter.shared)
}
