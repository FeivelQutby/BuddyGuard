import SwiftUI

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var isEditable: Bool = false

    @State private var isEditing = false
    @State private var editText = ""
    @State private var isSaving = false
    @Environment(AuthManager.self) private var authManager
    @FocusState private var isFocused: Bool

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

                if isEditing {
                    HStack(spacing: 8) {
                        TextField("Your name", text: $editText)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.darkActive)
                            .focused($isFocused)
                            .autocorrectionDisabled()
                            .onSubmit { save() }

                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Button { save() } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.normalActiveNd)
                            }
                            .disabled(editText.trimmingCharacters(in: .whitespaces).isEmpty)

                            Button { cancelEditing() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text(value)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.darkActive)
                }
            }

            Spacer()

            if isEditable && !isEditing {
                Image(systemName: "pencil")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isEditable && !isEditing else { return }
            startEditing()
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .padding(.vertical, 10)
    }

    private func startEditing() {
        editText = value
        isEditing = true
        isFocused = true
    }

    private func cancelEditing() {
        isEditing = false
        isFocused = false
    }

    private func save() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != value else {
            cancelEditing()
            return
        }
        isSaving = true
        Task {
            let success = await authManager.updateDisplayName(trimmed)
            isSaving = false
            if success {
                HapticManager.notification(.success)
                isEditing = false
                isFocused = false
            }
        }
    }
}
