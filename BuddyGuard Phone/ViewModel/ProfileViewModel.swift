//
//  ProfileViewModel.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 03/07/26.
//

import Foundation
import Observation

@Observable
final class ProfileViewModel {
    var selectedSegment: ProfileSegment
    var displayName: String
    var profileItems: [ProfileInfoItem]
    var emergencyContacts: [EmergencyContact]

    init(
        selectedSegment: ProfileSegment = .profile,
        displayName: String = "Maya",
        profileItems: [ProfileInfoItem] = ProfileViewModel.sampleProfileItems,
        emergencyContacts: [EmergencyContact] = ProfileViewModel.sampleEmergencyContacts
    ) {
        self.selectedSegment = selectedSegment
        self.displayName = displayName
        self.profileItems = profileItems
        self.emergencyContacts = emergencyContacts
    }

    var sectionTitle: String {
        selectedSegment.sectionTitle
    }

    func addEmergencyContact() {
        // Hook add contact flow here when the form is ready.
    }
}

extension ProfileViewModel {
    static let sampleProfileItems = [
        ProfileInfoItem(icon: "person.fill", title: "Full Name", value: "Maya Mayianti"),
        ProfileInfoItem(icon: "phone.fill", title: "Phone Number", value: "+62 812 3716 9073"),
        ProfileInfoItem(icon: "house.fill", title: "Home Address", value: "Jl. Foresta, No.10"),
        ProfileInfoItem(icon: "briefcase.fill", title: "Office Address", value: "Green Office Park 9")
    ]

    static let sampleEmergencyContacts = [
        EmergencyContact(name: "Dinda"),
        EmergencyContact(name: "Melani"),
        EmergencyContact(name: "Charles"),
        EmergencyContact(name: "Tania")
    ]
}

enum ProfileSegment: CaseIterable, Hashable {
    case profile
    case contact

    var title: String {
        switch self {
        case .profile:
            return "Profile"
        case .contact:
            return "Contact"
        }
    }

    var sectionTitle: String {
        switch self {
        case .profile:
            return "Profile Information"
        case .contact:
            return "Emergency Contact"
        }
    }

    var systemImage: String {
        switch self {
        case .profile:
            return "person.fill"
        case .contact:
            return "person.2.fill"
        }
    }
}
