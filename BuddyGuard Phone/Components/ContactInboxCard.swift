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

// MARK: - Inbox Row Card Component
private struct InboxRequestRow: View {
    let invitation: ContactInvitation
    let manager: EmergencyContactManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(.lightD2)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(invitation.senderName.prefix(1).uppercased())
                            .font(.body.weight(.bold))
                            .foregroundStyle(.darkActive)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(invitation.senderName)
                        .font(.headline)
                        .foregroundStyle(.darkActive)
                    Text(invitation.senderEmail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Wants to: \(invitation.senderPermission.title)")
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.lightD2)
                .clipShape(Capsule())
                .foregroundStyle(.darkActive)

            HStack(spacing: 12) {
                Button {
                    HapticManager.notification(.success)
                    Task {
                        await manager.respondToInvitation(invitation, accept: true)
                    }
                } label: {
                    Text("Accept")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.normalActiveNd)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    HapticManager.impact(.light)
                    Task {
                        await manager.respondToInvitation(invitation, accept: false)
                    }
                } label: {
                    Text("Decline")
                        .font(.subheadline.bold())
                        .foregroundStyle(.darkActive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.lightD2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(.lightD)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Light") {
    ContactInboxCard()
}

#Preview("Dark") {
    ContactInboxCard()
        .preferredColorScheme(.dark)
}
