//
//  ProfileView.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @Environment(AuthManager.self) private var authManager
    
    // MARK: - Presentation States
    @State private var showAddContactSheet = false
    @State private var showInboxSheet = false
    @State private var showEditNameSheet = false
    @State private var contactManager = EmergencyContactManager()

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        
        ZStack(alignment: .bottom) {
            VStack(spacing: 8) {
                
                // MARK: - Avatar
                Circle()
                    .foregroundStyle(.gray)
                    .opacity(0.5)
                    .overlay(
                        Text(authManager.displayName.prefix(1).uppercased())
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .frame(width: 110, height: 110)

                // MARK: - Name + Email from Firebase Auth
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(authManager.displayName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.darkActive)
                        Button {
                            showEditNameSheet = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(authManager.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Picker("Profile Section", selection: $viewModel.selectedSegment) {
                    ForEach(ProfileSegment.allCases, id: \.self) { segment in
                        Label(segment.title, systemImage: segment.systemImage)
                            .tag(segment)
                            .foregroundStyle(.darkActive)
                    }
                }
                .pickerStyle(.segmented)
                .tint(.dark)
                .padding(.top, 8)

                HStack(alignment: .firstTextBaseline) {
                    Text(viewModel.sectionTitle)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.darkActive)
                    
                    Spacer()
                    
                    // MARK: - Inbox Access Button with Badge
                    if viewModel.selectedSegment == .contact {
                        Button(action: { showInboxSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.badge")
                                Text("Inbox")
                                if contactManager.pendingInvitationCount > 0 {
                                    Text("\(contactManager.pendingInvitationCount)")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(.red))
                                }
                            }
                            .font(.subheadline.weight(.medium))
                        }
                        .padding(.trailing, 12)
                    }
                }
                .padding(.top, 20)

                switch viewModel.selectedSegment {
                case .profile:
                    ProfileInfoSection(authManager: authManager)
                        .padding(.top, 12)
                case .contact:
                    EmergencyContactList(
                        contacts: viewModel.emergencyContacts,
                        contactManager: contactManager
                    )
                    .padding(.top, 12)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // MARK: - Bottom Action Buttons
            if viewModel.selectedSegment == .contact {
                Button {
                    showAddContactSheet = true
                } label: {
                    Text("Add Emergency Contact")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.normalActiveNd)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 28)
                
            } else if viewModel.selectedSegment == .profile {
                Button {
                    authManager.signOut()
                } label: {
                    Text("Log Out")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showAddContactSheet) { AddContactSheet() }
        .sheet(isPresented: $showInboxSheet) { ContactInboxView() }
        .sheet(isPresented: $showEditNameSheet) {
            EditDisplayNameSheet(authManager: authManager)
        }
        .onAppear {
            contactManager.startListeningToInbox()
        }
    }
}

// MARK: - Profile Info Section (real auth data)

private struct ProfileInfoSection: View {
    let authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color(.systemGray3))
            
            ProfileInfoRow(icon: "person.fill", title: "Display Name", value: authManager.displayName)
            Divider().background(Color(.systemGray3))
            ProfileInfoRow(icon: "envelope.fill", title: "Email", value: authManager.email)
            Divider().background(Color(.systemGray3))
            ProfileInfoRow(
                icon: authManager.currentUser?.providerData.first?.providerID == "google.com" ? "g.circle.fill" : "applelogo",
                title: "Sign-in Method",
                value: authManager.currentUser?.providerData.first?.providerID == "google.com" ? "Google" : "Apple"
            )
        }
    }
}

private struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.lightD2)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.darkActive)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.darkActive)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Edit Display Name Sheet

private struct EditDisplayNameSheet: View {
    let authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Display Name")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("Your name", text: $newName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .autocorrectionDisabled()
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Button {
                    guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    isSaving = true
                    Task {
                        let success = await authManager.updateDisplayName(newName)
                        isSaving = false
                        if success {
                            dismiss()
                        } else {
                            errorMessage = "Failed to update name. Please try again."
                        }
                    }
                } label: {
                    HStack {
                        if isSaving { ProgressView().tint(.white).padding(.trailing, 6) }
                        Text("Save")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(newName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color("normalActive", bundle: nil))
                    .clipShape(Capsule())
                }
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                .padding(.bottom, 8)
            }
            .padding(24)
            .navigationTitle("Edit Display Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { newName = authManager.displayName }
        }
    }
}

// MARK: - Emergency Contact List

private struct EmergencyContactList: View {
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

private struct EmergencyContactRow: View {
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
                // Show real name in parentheses if nickname is set
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

// MARK: - Permission + Nickname Editing Sheet

private struct ContactPermissionSheet: View {
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
                // Contact Info Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 72, height: 72)
                        Text(contact.name.prefix(1).uppercased())
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)
                    Text(contact.name)
                        .font(.title2.weight(.bold))
                    Text(contact.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Nickname Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nickname (optional)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("e.g. Mom, BFF, Partner", text: $nickname)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 16)
                
                // Permission Toggles
                VStack(spacing: 0) {
                    Toggle(isOn: $canSendTo) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Send My Alerts")
                                .font(.body.weight(.medium))
                            Text("They can see your live location")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 16)
                    
                    Divider().padding(.leading, 16)
                    
                    Toggle(isOn: $canReceiveFrom) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Receive Their Alerts")
                                .font(.body.weight(.medium))
                            Text("You can see their live location")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 16)
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Save Button
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
                    .background(Color("normalActive", bundle: nil))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .disabled(isSaving)
                
                // Remove Contact Button
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
                    Button("Close") { dismiss() }
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

#Preview("Light Mode") {
    ProfileView()
        .environment(AuthManager())
}

#Preview("Dark Mode") {
    ProfileView()
        .preferredColorScheme(.dark)
        .environment(AuthManager())
}
