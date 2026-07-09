import SwiftUI

struct EmergencyContactRow: View {
    let contact: EmergencyContact
    let contactManager: EmergencyContactManager
    @State private var showPermissionSheet = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.lightD2)
                    .frame(width: 44, height: 44)
                Text(contact.displayName.prefix(1).uppercased())
                    .font(.body.weight(.bold))
                    .foregroundStyle(.darkActive)
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
                Image(systemName: "slider.horizontal.3")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .sheet(isPresented: $showPermissionSheet) {
            ContactPermissionSheet(contact: contact, contactManager: contactManager)
        }
    }

    private var permissionLabel: String {
        if contact.canSendTo && contact.canReceiveFrom { return "Send & Receive" }
        else if contact.canSendTo { return "Send Only" }
        else if contact.canReceiveFrom { return "Receive Only" }
        else { return "No Permissions" }
    }
}
