import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @Environment(AuthManager.self) private var authManager

    @State private var showAddContactSheet = false
    @State private var showInboxSheet = false
    @State private var contactManager = EmergencyContactManager()

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack(alignment: .bottom) {
            VStack(spacing: 8) {

                Circle()
                    .foregroundStyle(.lightD2)
                    .opacity(0.5)
                    .overlay(
                        Text(authManager.displayName.prefix(1).uppercased())
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(.darkActive)
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

                    if viewModel.selectedSegment == .contact {
                        Button(action: { showInboxSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.badge")
                                Text("Inbox")
                                if contactManager.pendingInvitationCount > 0 {
                                    Text("\(contactManager.pendingInvitationCount)")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(.red))
                                }
                            }
                            .font(.subheadline.weight(.medium))
                        }
                        .padding(.trailing, 12)
                    }
                }
                .padding(.top, 20)

                switch viewModel.selectedSegment {
                case .profile:
                    ProfileInfoSection(authManager: authManager)
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
        .sheet(isPresented: $showInboxSheet) {
            ContactInboxCard()
                .presentationDetents([.medium,.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            contactManager.startListeningToInbox()
        }
    }
}

#Preview("Light Mode") {
    ProfileView()
        .environment(AuthManager())
}

#Preview("Dark Mode") {
    ProfileView()
        .preferredColorScheme(.dark)
        .environment(AuthManager())
}
