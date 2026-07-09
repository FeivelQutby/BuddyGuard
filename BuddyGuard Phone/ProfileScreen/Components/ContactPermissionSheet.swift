import SwiftUI

struct ContactPermissionSheet: View {
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
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(.lightD2)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Text(contact.name.prefix(1).uppercased())
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.darkActive)
                        )
                        .padding(.top, 16)
                    Text(contact.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.darkActive)
                    Text(contact.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nickname (optional)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("e.g. Mom, BFF, Partner", text: $nickname)
                        .padding()
                        .background(.lightD2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .autocorrectionDisabled()
                        .foregroundStyle(.darkActive)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    Toggle(isOn: $canSendTo) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Send My Alerts")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.darkActive)
                            Text("They can see your live location")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .tint(.normalActiveNd)
                    .padding(.vertical, 12).padding(.horizontal, 16)

                    Divider().padding(.leading, 16)

                    Toggle(isOn: $canReceiveFrom) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Receive Their Alerts")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.darkActive)
                            Text("You can see their live location")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .tint(.normalActiveNd)
                    .padding(.vertical, 12).padding(.horizontal, 16)
                }
                .background(.lightD2)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                Spacer()

                Button {
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
                } label: {
                    HStack {
                        if isSaving { ProgressView().tint(.white).padding(.trailing, 6) }
                        Text("Save Changes").font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.normalActiveNd)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .disabled(isSaving)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Remove Contact")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Edit Contact")
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
}
