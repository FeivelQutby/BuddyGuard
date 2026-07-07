//
//  ContactInboxView.swift
//  BuddyGuard
//
//  Created by George Maximillian Theodore on 06/07/26.
//


import SwiftUI

struct ContactInboxView: View {
    @State private var contactManager = EmergencyContactManager()
    
    var body: some View {
        NavigationStack {
            Group {
                if contactManager.incomingInvitations.isEmpty {
                    ContentUnavailableView(
                        "Your Inbox is Empty",
                        systemImage: "envelope.open.fill",
                        description: Text("Pending emergency contact invitations will show up here.")
                    )
                } else {
                    List(contactManager.incomingInvitations) { invitation in
                        InboxRequestRow(invitation: invitation, manager: contactManager)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Invitations")
            .onAppear {
                contactManager.startListeningToInbox()
            }
        }
    }
}

// MARK: - Inbox Row Card Component
private struct InboxRequestRow: View {
    let invitation: ContactInvitation
    let manager: EmergencyContactManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.title)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(invitation.senderName)
                        .font(.headline)
                    Text(invitation.senderEmail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Displays what the sender requested configuration-wise
            Text("Wants to: \(invitation.senderPermission.title)")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                // Accept Button
                Button {
                    Task {
                        await manager.respondToInvitation(invitation, accept: true)
                    }
                } label: {
                    Text("Accept")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color("normalActive", bundle: nil))
                        .cornerRadius(8)
                }
                
                // Decline Button
                Button {
                    Task {
                        await manager.respondToInvitation(invitation, accept: false)
                    }
                } label: {
                    Text("Decline")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray4))
                        .cornerRadius(8)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color("lightD", bundle: nil))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ContactInboxView()
}