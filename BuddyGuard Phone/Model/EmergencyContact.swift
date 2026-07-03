//
//  EmergencyContact.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 03/07/26.
//

import Foundation

struct EmergencyContact: Identifiable {
    let id: UUID
    let name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
