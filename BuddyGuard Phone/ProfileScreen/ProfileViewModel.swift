//
//  ProfileViewModel.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 03/07/26.
//

import Foundation
import Observation
import FirebaseFirestore
import FirebaseAuth

@Observable
final class ProfileViewModel {
    var selectedSegment: ProfileSegment
    var emergencyContacts: [EmergencyContact]
    
    // Database properties for live coordination
    private let db = Firestore.firestore()
    private var contactsListener: ListenerRegistration?

    init(
        selectedSegment: ProfileSegment = .profile,
        emergencyContacts: [EmergencyContact] = []
    ) {
        self.selectedSegment = selectedSegment
        self.emergencyContacts = emergencyContacts
        
        // Start monitoring live connections automatically
        listenToLiveContacts()
    }
    
    deinit {
        // Detach listener when leaving the screen to preserve connection bandwidth
        contactsListener?.remove()
    }

    var sectionTitle: String {
        selectedSegment.sectionTitle
    }

    // MARK: - Live Database Sync Logic
    
    func listenToLiveContacts() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing listener if re-initializing
        contactsListener?.remove()
        
        // Listen directly to the user's personal trusted contacts subcollection
        contactsListener = db.collection("users").document(currentUID).collection("contacts")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self, let documents = querySnapshot?.documents else {
                    print("Error fetching dynamic contacts: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Perform asynchronous profile expansion off the main thread
                Task {
                    var loadedContacts: [EmergencyContact] = []
                    
                    for document in documents {
                        let contactUID = document.documentID
                        let data = document.data()
                        
                        let canSendTo = data["canSendTo"] as? Bool ?? false
                        let canReceiveFrom = data["canReceiveFrom"] as? Bool ?? false
                        let nickname = data["nickname"] as? String
                        
                        // Look up the companion profile details dynamically via their base document profile metadata
                        if let profileDoc = try? await self.db.collection("users").document(contactUID).getDocument(),
                           let profileData = profileDoc.data() {
                            
                            let name = profileData["name"] as? String ?? "Trusted Companion"
                            let email = profileData["email"] as? String ?? ""
                            
                            let verifiedContact = EmergencyContact(
                                id: contactUID,
                                name: name,
                                email: email,
                                canSendTo: canSendTo,
                                canReceiveFrom: canReceiveFrom,
                                nickname: nickname
                            )
                            loadedContacts.append(verifiedContact)
                        }
                    }
                    
                    // Safely push updates back to the UI layout sequence
                    await MainActor.run {
                        self.emergencyContacts = loadedContacts
                    }
                }
            }
    }
}

extension ProfileViewModel {
    // Updated with proper parameters to eliminate structural initialization mismatch errors
    static let sampleProfileContacts = [
        EmergencyContact(id: "sample1", name: "Dinda", email: "dinda@example.com", canSendTo: true, canReceiveFrom: true),
        EmergencyContact(id: "sample2", name: "Melani", email: "melani@example.com", canSendTo: true, canReceiveFrom: false),
        EmergencyContact(id: "sample3", name: "Charles", email: "charles@example.com", canSendTo: false, canReceiveFrom: true),
        EmergencyContact(id: "sample4", name: "Tania", email: "tania@example.com", canSendTo: true, canReceiveFrom: true)
    ]
}

enum ProfileSegment: CaseIterable, Hashable {
    case profile
    case contact

    var title: String {
        switch self {
        case .profile: return "Profile"
        case .contact: return "Contact"
        }
    }

    var sectionTitle: String {
        switch self {
        case .profile: return "Profile Information"
        case .contact: return "Emergency Contact"
        }
    }

    var systemImage: String {
        switch self {
        case .profile: return "person.fill"
        case .contact: return "person.2.fill"
        }
    }
}
