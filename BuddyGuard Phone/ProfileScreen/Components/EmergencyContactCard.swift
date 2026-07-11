import SwiftUI

struct EmergencyContactCard: View {
    let contact: EmergencyContact
    let contactManager: EmergencyContactManager
    @State private var showPermissionSheet = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.normalActiveNd)
                    .frame(width: 44, height: 44)
                Text(contact.displayName.prefix(1).uppercased())
                    .font(.body.weight(.bold))
                    .foregroundStyle(.light)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.darkActive)
                if contact.nickname != nil, !contact.name.isEmpty {
                    Text(contact.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(permissionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { showPermissionSheet = true } label: {
                Image(systemName: "pencil")
                    .font(.body)
                    .foregroundStyle(.darkActive)
            }
        }
        .padding(.vertical, 10)
        .sheet(isPresented: $showPermissionSheet) {
            EditContactSheet(contact: contact, contactManager: contactManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var permissionLabel: String {
        if contact.canSendTo && contact.canReceiveFrom { return "Send & Receive" }
        else if contact.canSendTo { return "Send Only" }
        else if contact.canReceiveFrom { return "Receive Only" }
        else { return "No Permissions" }
    }
}

#Preview("Send & Receive") {
    EmergencyContactCard(
        contact: ProfileViewModel.sampleProfileContacts[0],
        contactManager: EmergencyContactManager()
    )
    .padding(16)
}

#Preview("Send & Receive Dark") {
    EmergencyContactCard(
        contact: ProfileViewModel.sampleProfileContacts[0],
        contactManager: EmergencyContactManager()
    )
    .padding(16)
    .preferredColorScheme(.dark)
}

#Preview("With Nickname") {
    EmergencyContactCard(
        contact: EmergencyContact(id: "nick1", name: "Dinda Pratiwi", email: "dinda@example.com", canSendTo: true, canReceiveFrom: true, nickname: "Mom"),
        contactManager: EmergencyContactManager()
    )
    .padding(16)
}



#Preview("With Nickname Dark") {
    EmergencyContactCard(
        contact: EmergencyContact(id: "nick1", name: "Dinda Pratiwi", email: "dinda@example.com", canSendTo: true, canReceiveFrom: true, nickname: "Mom"),
        contactManager: EmergencyContactManager()
    )
    .padding(16)
    .preferredColorScheme(ColorScheme.dark)
}
