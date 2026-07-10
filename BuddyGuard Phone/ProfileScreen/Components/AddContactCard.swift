import SwiftUI

struct AddContactCard: View {
    let invitation: ContactInvitation
    let manager: EmergencyContactManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(.normalActiveNd)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(invitation.senderName.prefix(1).uppercased())
                            .font(.body.weight(.bold))
                            .foregroundStyle(.light)
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
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    HapticManager.impact(.light)
                    Task {
                        await manager.respondToInvitation(invitation, accept: false)
                    }
                } label: {
                    Text("Decline")
                        .font(.subheadline.bold())
                        .foregroundStyle(.light)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.normalActiveNd)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button {
                    HapticManager.notification(.success)
                    Task {
                        await manager.respondToInvitation(invitation, accept: true)
                    }
                } label: {
                    Text("Accept")
                        .font(.subheadline.bold())
                        .foregroundStyle(.light)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.normalActiveNd)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(.lightD)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Light") {
    AddContactCard(
        invitation: ContactInvitation(
            id: "preview1",
            senderId: "user1",
            senderEmail: "maya@example.com",
            senderName: "Maya",
            receiverId: "me",
            senderPermission: .both,
            status: .pending,
            timestamp: Date()
        ),
        manager: EmergencyContactManager()
    )
    .padding(16)
}

#Preview("Dark") {
    AddContactCard(
        invitation: ContactInvitation(
            id: "preview1",
            senderId: "user1",
            senderEmail: "maya@example.com",
            senderName: "Maya",
            receiverId: "me",
            senderPermission: .sendOnly,
            status: .pending,
            timestamp: Date()
        ),
        manager: EmergencyContactManager()
    )
    .padding(16)
    .preferredColorScheme(.dark)
}
