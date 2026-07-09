import SwiftUI

struct InboxRequestRow: View {
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
