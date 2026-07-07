//
//  EmergencyContact.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 03/07/26.
//

import Foundation
import FirebaseFirestore

enum InvitationPermission: String, Codable, CaseIterable {
    case sendOnly = "send"
    case receiveOnly = "receive"
    case both = "both"
    
    var title: String {
        switch self {
        case .sendOnly: return "Only Send My Alerts"
        case .receiveOnly: return "Only Receive Their Alerts"
        case .both: return "Send & Receive Both"
        }
    }
}

enum InvitationStatus: String, Codable {
    case pending
    case accepted
    case declined
}

struct ContactInvitation: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let senderEmail: String
    let senderName: String
    let receiverId: String
    let senderPermission: InvitationPermission
    let status: InvitationStatus
    let timestamp: Date?
}

struct EmergencyContact: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    var canSendTo: Bool
    var canReceiveFrom: Bool
    /// Optional personal label the current user can set for this contact
    var nickname: String?
    
    /// The display label — shows nickname if set, otherwise real name
    var displayName: String {
        if let nick = nickname, !nick.trimmingCharacters(in: .whitespaces).isEmpty {
            return nick
        }
        return name
    }
}
