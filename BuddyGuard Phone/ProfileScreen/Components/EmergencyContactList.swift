import SwiftUI

struct EmergencyContactList: View {
    let contacts: [EmergencyContact]
    let contactManager: EmergencyContactManager

    var body: some View {
        if contacts.isEmpty {
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
        } else {
            VStack(spacing: 0) {
                Divider().background(Color(.systemGray3))
                ForEach(contacts) { contact in
                    EmergencyContactRow(contact: contact, contactManager: contactManager)
                    if contact.id != contacts.last?.id {
                        Divider().background(Color(.systemGray3))
                    }
                }
            }
        }
    }
}
