//
//  ProfileView.swift
//  BuddyGuard
//
//  Created by Feivel Qutby on 02/07/26.
//

import SwiftUI

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 8) {
                Circle()
                    .foregroundStyle(.gray)
                    .opacity(0.5)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.title)
                            .foregroundStyle(.gray)
                    )
                    .frame(width: 150, height: 150)

                Text(viewModel.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.darkActive)

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
                    Button(action: {}) {
                        Text("Edit")
                    }
                }
                .padding(.top, 28)

                switch viewModel.selectedSegment {
                case .profile:
                    ProfileInfoList(items: viewModel.profileItems)
                        .padding(.top, 16)
                case .contact:
                    EmergencyContactList(contacts: viewModel.emergencyContacts)
                        .padding(.top, 16)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if viewModel.selectedSegment == .contact {
                Button {
                    viewModel.addEmergencyContact()
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
            }
        }
    }
}

private struct ProfileInfoList: View {
    let items: [ProfileInfoItem]

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(.systemGray3))

            ForEach(items) { item in
                ProfileInfoRow(item: item)

                if item.id != items.last?.id {
                    Divider()
                        .background(Color(.systemGray3))
                }
            }
        }
    }
}

private struct ProfileInfoRow: View {
    let item: ProfileInfoItem

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.light)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: item.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.darkActiveNd)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(.labelSecond)

                Text(item.value)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.darkActive)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

private struct EmergencyContactList: View {
    let contacts: [EmergencyContact]

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(.systemGray3))

            ForEach(contacts) { contact in
                EmergencyContactRow(contact: contact)

                if contact.id != contacts.last?.id {
                    Divider()
                        .background(Color(.systemGray3))
                }
            }
        }
    }
}

private struct EmergencyContactRow: View {
    let contact: EmergencyContact

    var body: some View {
            HStack(spacing: 16) {
                Circle()
                    .fill(.light)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.darkActiveNd)
                    )

                Text(contact.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.darkActive)

                Spacer()
            }
            .padding(.vertical,8)
    }
}

#Preview("Light Mode") {
    ProfileView()
}

#Preview("Dark Mode") {
    ProfileView()
    .preferredColorScheme(.dark)
}
