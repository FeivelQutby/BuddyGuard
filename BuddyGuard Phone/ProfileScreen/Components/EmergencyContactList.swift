import SwiftUI

struct EmergencyContactList: View {
    let contacts: [EmergencyContact]
    let contactManager: EmergencyContactManager

    var body: some View {
        VStack(spacing: 12) {
            // Pending invitations at the top
            ForEach(contactManager.incomingInvitations) { invitation in
                AddContactCard(invitation: invitation, manager: contactManager)
            }

            if contacts.isEmpty && contactManager.incomingInvitations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No emergency contacts yet")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
            } else if !contacts.isEmpty {
                VStack(spacing: 0) {
                    Divider().background(.secondary)
                    ForEach(contacts) { contact in
                        EmergencyContactCard(contact: contact, contactManager: contactManager)
                        if contact.id != contacts.last?.id {
                            Divider().background(.secondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview("Contacts") {
    EmergencyContactList(
        contacts: ProfileViewModel.sampleProfileContacts,
        contactManager: EmergencyContactManager()
    )
    .padding(16)
}

#Preview("Contacts Dark") {
    EmergencyContactList(
        contacts: ProfileViewModel.sampleProfileContacts,
        contactManager: EmergencyContactManager()
    )
    .padding(16)
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    EmergencyContactList(
        contacts: [],
        contactManager: EmergencyContactManager()
    )
    .padding(16)
}
