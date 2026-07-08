//
//  AddContactSheet.swift
//  BuddyGuard
//
//  Created by George Maximillian Theodore on 06/07/26.
//


import SwiftUI

struct AddContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contactManager = EmergencyContactManager()
    
    @State private var email: String = ""
    @State private var selectedPermission: InvitationPermission = .both
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                
                // Form Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Emergency Contact Email")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    TextField("example@email.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Permission Selector Section
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
                    .padding(.horizontal, 4)
                }
                
                // Async Network Status Feedback
                if !contactManager.statusMessage.isEmpty {
                    Text(contactManager.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(contactManager.statusMessage.contains("successfully") ? .green : .red)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Send Action Button
                Button {
                    Task {
                        await contactManager.sendInvitation(toEmail: email, permission: selectedPermission)
                        // Optional: Dismiss sheet on success after a short delay
                        if contactManager.statusMessage.contains("successfully") {
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
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(email.isEmpty ? Color.gray : Color("normalActive")) // ini normal active masih blom bisa
                    .clipShape(Capsule())
                }
                .disabled(email.isEmpty)
            }
            .padding(24)
            .navigationTitle("Add Trusted Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddContactSheet()
}

#Preview {
    AddContactSheet()
        .preferredColorScheme(.dark)
}
