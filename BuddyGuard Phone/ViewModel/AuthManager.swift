//
//  AuthManager.swift
//  BuddyGuard
//
//  Created by George Maximillian Theodore on 06/07/26.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

@Observable
class AuthManager {
    var isAuthenticated = false
    var currentUser: User?
    
    /// Convenience: the user's display name from Firebase Auth
    var displayName: String {
        currentUser?.displayName ?? currentUser?.email?.components(separatedBy: "@").first ?? "User"
    }
    
    /// Convenience: the user's email from Firebase Auth
    var email: String {
        currentUser?.email ?? ""
    }
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    func startListening() {
        Auth.auth().addStateDidChangeListener { auth, user in
            self.currentUser = user
            self.isAuthenticated = (user != nil)
            
            if let activeUser = user {
                self.saveUserToDatabase(user: activeUser)
            }
        }
    }
    
    private func saveUserToDatabase(user: User) {
        let userRef = db.collection("users").document(user.uid)
        
        // We use merge: true so we don't accidentally delete their friends list
        // if they log in a second time!
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "name": user.displayName ?? "Unknown User"
        ]
        
        userRef.setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user profile: \(error.localizedDescription)")
            } else {
                print("User profile synced to Firestore!")
            }
        }
    }
    
    // MARK: - Update Display Name
    
    /// Updates the Firebase Auth display name and syncs it back to Firestore.
    func updateDisplayName(_ newName: String) async -> Bool {
        guard let user = Auth.auth().currentUser, !newName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        
        do {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = trimmed
            try await changeRequest.commitChanges()
            
            // Sync to Firestore
            let batch = db.batch()
            batch.updateData(["name": trimmed], forDocument: db.collection("users").document(user.uid))
            
            // Sync to all friends so their snapshot listeners trigger
            let myContacts = try await db.collection("users").document(user.uid).collection("contacts").getDocuments()
            for doc in myContacts.documents {
                let friendContactRef = db.collection("users").document(doc.documentID)
                    .collection("contacts").document(user.uid)
                batch.updateData(["name": trimmed], forDocument: friendContactRef)
            }
            
            try await batch.commit()
            
            // Update local state
            self.currentUser = Auth.auth().currentUser
            print("✅ Display name updated to \(trimmed) and synced to friends")
            return true
        } catch {
            print("⚠️ Failed to update display name: \(error.localizedDescription)")
            return false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
