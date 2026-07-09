import SwiftUI

struct AddContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contactManager = EmergencyContactManager()

    @State private var email: String = ""
    @State private var selectedPermission: InvitationPermission = .both

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {

                VStack(alignment: .leading, spacing: 16) {
                    Text("Emergency Contact Email")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("example@email.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.lightD)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.darkActive)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Access Configuration")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Permissions", selection: $selectedPermission) {
                        ForEach(InvitationPermission.allCases, id: \.self) { permission in
                            Text(permission.title).tag(permission)
                        }
                    }
                    .pickerStyle(.inline)
                    .tint(.normalActive)
                    .background(.lightD)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !contactManager.statusMessage.isEmpty {
                    Text(contactManager.statusMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(contactManager.statusMessage.contains("successfully") ? .green : .red)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button {
                    Task {
                        await contactManager.sendInvitation(toEmail: email, permission: selectedPermission)
                        if contactManager.statusMessage.contains("successfully") {
                            HapticManager.notification(.success)
                            try? await Task.sleep(for: .seconds(1.5))
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if contactManager.statusMessage == "Searching..." {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                        }
                        Text("Send Invitation")
                            .font(.headline)
                    }
                    .foregroundStyle(.light)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.normalActiveNd)
                    .clipShape(Capsule())
                }
                .disabled(email.isEmpty)
            }
            .padding(24)
            .navigationTitle("Add Trusted Contact")
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
        }
    }
}

#Preview("Light") {
    AddContactSheet()
}

#Preview("Dark") {
    AddContactSheet()
        .preferredColorScheme(.dark)
}
