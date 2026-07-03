//
//  ProfileInfoItem.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 03/07/26.
//

import Foundation

struct ProfileInfoItem: Identifiable {
    let id: UUID
    let icon: String
    let title: String
    let value: String

    init(id: UUID = UUID(), icon: String, title: String, value: String) {
        self.id = id
        self.icon = icon
        self.title = title
        self.value = value
    }
}
