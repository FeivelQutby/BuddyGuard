import SwiftUI

struct ContactInboxCard: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contactManager = EmergencyContactManager()

    var body: some View {
        NavigationStack {
            Group {
                if contactManager.incomingInvitations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Your Inbox is Empty")
                            .font(.headline)
                            .foregroundStyle(.darkActive)
                        Text("Pending emergency contact invitations will show up here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    List(contactManager.incomingInvitations) { invitation in
                        InboxRequestRow(invitation: invitation, manager: contactManager)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Invitations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.lightD2)
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear {
                contactManager.startListeningToInbox()
            }
        }
    }
}

#Preview("Light") {
    ContactInboxCard()
}

#Preview("Dark") {
    ContactInboxCard()
        .preferredColorScheme(.dark)
}
