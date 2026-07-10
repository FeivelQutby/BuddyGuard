import SwiftUI

struct SettingsContactSheet: View {
    let contact: EmergencyContact
    let contactManager: EmergencyContactManager

    @Environment(\.dismiss) private var dismiss
    @State private var canSendTo: Bool
    @State private var canReceiveFrom: Bool
    @State private var nickname: String
    @State private var showDeleteConfirmation = false
    @State private var isSaving = false

    init(contact: EmergencyContact, contactManager: EmergencyContactManager) {
        self.contact = contact
        self.contactManager = contactManager
        _canSendTo = State(initialValue: contact.canSendTo)
        _canReceiveFrom = State(initialValue: contact.canReceiveFrom)
        _nickname = State(initialValue: contact.nickname ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(.lightD2)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(contact.name.prefix(1).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.darkActive)
                        )
                    Text(contact.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.darkActive)
                    Text(contact.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Nickname (optional)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("e.g. Mom, BFF, Partner", text: $nickname)
                        .padding(12)
                        .background(.lightD)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .autocorrectionDisabled()
                        .foregroundStyle(.darkActive)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    Toggle(isOn: $canSendTo) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Send My Alerts")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.darkActive)
                            Text("They can see your live location")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .tint(.normalActiveNd)
                    .padding(.vertical, 10).padding(.horizontal, 16)

                    Divider().padding(.leading, 16)

                    Toggle(isOn: $canReceiveFrom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Receive Their Alerts")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.darkActive)
                            Text("You can see their live location")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .tint(.normalActiveNd)
                    .padding(.vertical, 10).padding(.horizontal, 16)
                }
                .background(.lightD)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Remove Contact")
                        .font(.subheadline.weight(.medium))
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Save")
                                .font(.subheadline.weight(.semibold))
//                                .background(.normalActiveNd)
                                .foregroundStyle(.secondary)
                    
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .alert("Remove Contact", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    Task {
                        await contactManager.removeContact(contactUID: contact.id)
                        dismiss()
                    }
                }
            } message: {
                Text("Remove \(contact.displayName) as an emergency contact? This cannot be undone.")
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            async let p1: () = contactManager.updateContactPermission(
                contactUID: contact.id,
                canSendTo: canSendTo,
                canReceiveFrom: canReceiveFrom
            )
            async let p2: () = contactManager.updateNickname(
                contactUID: contact.id,
                nickname: nickname.isEmpty ? nil : nickname
            )
            _ = await (p1, p2)
            isSaving = false
            dismiss()
        }
    }
}

#Preview("Light") {
    SettingsContactSheet(
        contact: ProfileViewModel.sampleProfileContacts[0],
        contactManager: EmergencyContactManager()
    )
}

#Preview("Dark") {
    SettingsContactSheet(
        contact: ProfileViewModel.sampleProfileContacts[0],
        contactManager: EmergencyContactManager()
    )
    .preferredColorScheme(.dark)
}
