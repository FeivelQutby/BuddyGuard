//
//  EmergencyContactManager.swift
//  BuddyGuard
//
//  Created by George Maximillian Theodore on 06/07/26.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

@Observable
class EmergencyContactManager {
    private let db = Firestore.firestore()
    private var inboxListener: ListenerRegistration?
    
    var incomingInvitations: [ContactInvitation] = []
    var statusMessage: String = ""
    
    /// Live count of pending invitations for the badge
    var pendingInvitationCount: Int {
        incomingInvitations.count
    }
    
    deinit {
        inboxListener?.remove()
    }
    
    // MARK: - 1. Send Invitation with Specified Permissions
    func sendInvitation(toEmail email: String, permission: InvitationPermission) async {
        guard let currentUser = Auth.auth().currentUser else {
            self.statusMessage = "You must be logged in."
            return
        }
        
        let targetEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Prevent self-invitation
        if targetEmail == (currentUser.email ?? "").lowercased() {
            self.statusMessage = "You can't add yourself as a contact."
            return
        }
        
        self.statusMessage = "Searching..."
        
        do {
            // Find target user by email
            let snapshot = try await db.collection("users")
                .whereField("email", isEqualTo: targetEmail).getDocuments()
            
            guard let targetDoc = snapshot.documents.first else {
                self.statusMessage = "No user found with that email."
                return
            }
            
            let receiverId = targetDoc.documentID
            
            // Check if they're already contacts
            let existingContact = try await db.collection("users").document(currentUser.uid)
                .collection("contacts").document(receiverId).getDocument()
            
            if existingContact.exists {
                self.statusMessage = "This user is already your emergency contact."
                return
            }
            
            // Check if a PENDING invitation already exists between these users
            let existingInvites = try await db.collection("invitations")
                .whereField("senderId", isEqualTo: currentUser.uid)
                .whereField("receiverId", isEqualTo: receiverId)
                .whereField("status", isEqualTo: InvitationStatus.pending.rawValue)
                .getDocuments()
            
            let reverseInvites = try await db.collection("invitations")
                .whereField("senderId", isEqualTo: receiverId)
                .whereField("receiverId", isEqualTo: currentUser.uid)
                .whereField("status", isEqualTo: InvitationStatus.pending.rawValue)
                .getDocuments()
            
            // If there's any pending invite, block sending a new one
            if !existingInvites.isEmpty || !reverseInvites.isEmpty {
                self.statusMessage = "An invitation is already pending with this user."
                return
            }
            
            let newInvitation = ContactInvitation(
                senderId: currentUser.uid,
                senderEmail: currentUser.email ?? "",
                senderName: currentUser.displayName ?? "Someone",
                receiverId: receiverId,
                senderPermission: permission,
                status: .pending,
                timestamp: Date()
            )
            
            _ = try db.collection("invitations").addDocument(from: newInvitation)
            self.statusMessage = "Invitation sent successfully!"
            
        } catch {
            self.statusMessage = "Failed to invite: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 2. Real-time Inbox Listener for Incoming Requests
    func startListeningToInbox() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        // Remove any existing listener to prevent duplicates
        inboxListener?.remove()
        
        inboxListener = db.collection("invitations")
            .whereField("receiverId", isEqualTo: currentUserID)
            .whereField("status", isEqualTo: InvitationStatus.pending.rawValue)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self, let documents = querySnapshot?.documents else {
                    print("Error fetching invitations: \(error?.localizedDescription ?? "")")
                    return
                }
                self.incomingInvitations = documents.compactMap { try? $0.data(as: ContactInvitation.self) }
            }
    }
    
    // MARK: - 3. Process Accept / Decline Choices
    func respondToInvitation(_ invitation: ContactInvitation, accept: Bool) async {
        guard let inviteID = invitation.id else { return }
        guard let currentUser = Auth.auth().currentUser else { return }
        let inviteRef = db.collection("invitations").document(inviteID)
        
        if !accept {
            do {
                try await inviteRef.updateData(["status": InvitationStatus.declined.rawValue])
            } catch {
                print("Failed to decline invitation: \(error.localizedDescription)")
            }
            return
        }
        
        // Write transaction to ensure both user permission records update simultaneously
        let batch = db.batch()
        
        // Update Invitation Record
        batch.updateData(["status": InvitationStatus.accepted.rawValue], forDocument: inviteRef)
        
        // Determine bidirectional permissions mapping based on what sender requested
        var senderCanSend = false
        var senderCanReceive = false
        
        switch invitation.senderPermission {
        case .sendOnly:
            senderCanSend = true
        case .receiveOnly:
            senderCanReceive = true
        case .both:
            senderCanSend = true
            senderCanReceive = true
        }
        
        // Document path under Sender's subcollection
        let senderContactRef = db.collection("users").document(invitation.senderId)
            .collection("contacts").document(invitation.receiverId)
            
        // Document path under Receiver's subcollection (inverted perspectives)
        let receiverContactRef = db.collection("users").document(invitation.receiverId)
            .collection("contacts").document(invitation.senderId)
        
        // Fetch sender and receiver profile info for proper names
        let senderName = invitation.senderName
        let senderEmail = invitation.senderEmail
        
        var receiverName = currentUser.displayName ?? "Unknown"
        var receiverEmail = currentUser.email ?? ""
        
        // Enrich with Firestore profile data if available
        if let receiverDoc = try? await db.collection("users").document(currentUser.uid).getDocument(),
           let receiverData = receiverDoc.data() {
            receiverName = receiverData["name"] as? String ?? receiverName
            receiverEmail = receiverData["email"] as? String ?? receiverEmail
        }
        
        let senderData: [String: Any] = [
            "uid": invitation.receiverId,
            "name": receiverName,
            "email": receiverEmail,
            "canSendTo": senderCanSend,
            "canReceiveFrom": senderCanReceive
        ]
        
        let receiverData: [String: Any] = [
            "uid": invitation.senderId,
            "name": senderName,
            "email": senderEmail,
            "canSendTo": senderCanReceive, // Inverted: if sender receives, receiver sends to them
            "canReceiveFrom": senderCanSend
        ]
        
        batch.setData(senderData, forDocument: senderContactRef, merge: true)
        batch.setData(receiverData, forDocument: receiverContactRef, merge: true)
        
        do {
            try await batch.commit()
            print("✅ Successfully established contact permissions matrix.")
        } catch {
            print("Transaction failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 4. Update Contact Permissions
    
    /// Updates the permission flags for an existing contact relationship.
    /// Both sides of the relationship are updated atomically.
    func updateContactPermission(contactUID: String, canSendTo: Bool, canReceiveFrom: Bool) async {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        let batch = db.batch()
        
        // Update current user's view of the contact
        let myContactRef = db.collection("users").document(currentUID)
            .collection("contacts").document(contactUID)
        
        // Update the contact's view of the current user (inverted permissions)
        let theirContactRef = db.collection("users").document(contactUID)
            .collection("contacts").document(currentUID)
        
        batch.updateData([
            "canSendTo": canSendTo,
            "canReceiveFrom": canReceiveFrom
        ], forDocument: myContactRef)
        
        batch.updateData([
            "canSendTo": canReceiveFrom,   // Inverted: my receive = their send
            "canReceiveFrom": canSendTo     // Inverted: my send = their receive
        ], forDocument: theirContactRef)
        
        do {
            try await batch.commit()
            print("✅ Permissions updated for contact \(contactUID)")
        } catch {
            print("⚠️ Permission update failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 5. Remove Contact
    
    /// Removes a contact from both sides and cleans up any related invitations.
    func removeContact(contactUID: String) async {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        let batch = db.batch()
        
        let myContactRef = db.collection("users").document(currentUID)
            .collection("contacts").document(contactUID)
        let theirContactRef = db.collection("users").document(contactUID)
            .collection("contacts").document(currentUID)
        
        batch.deleteDocument(myContactRef)
        batch.deleteDocument(theirContactRef)
        
        do {
            try await batch.commit()
            print("✅ Contact \(contactUID) removed from both sides.")
        } catch {
            print("⚠️ Failed to remove contact: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 6. Fetch Emergency Contact UIDs
    
    /// Returns the list of UIDs of the current user's emergency contacts
    /// who can send alerts to this user (canReceiveFrom == true).
    func fetchReceivableContactUIDs() async -> [String] {
        guard let currentUID = Auth.auth().currentUser?.uid else { return [] }
        
        do {
            let snapshot = try await db.collection("users").document(currentUID)
                .collection("contacts")
                .whereField("canReceiveFrom", isEqualTo: true)
                .getDocuments()
            
            return snapshot.documents.map { $0.documentID }
        } catch {
            print("⚠️ Failed to fetch contact UIDs: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - 7. Update Nickname
    
    /// Saves a personal nickname for a contact. Only updates the current user's
    /// view of that contact — the other side is unaffected (it's personal).
    func updateNickname(contactUID: String, nickname: String?) async {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        let myContactRef = db.collection("users").document(currentUID)
            .collection("contacts").document(contactUID)
        
        let value: Any = nickname?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? nickname!.trimmingCharacters(in: .whitespaces)
            : NSNull()
        
        do {
            try await myContactRef.updateData(["nickname": value])
            print("✅ Nickname updated for contact \(contactUID)")
        } catch {
            print("⚠️ Nickname update failed: \(error.localizedDescription)")
        }
    }
}
