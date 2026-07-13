import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct EmergencyActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        var status: String
        var contactsNotified: Int
    }

    var userName: String
    var sessionId: String
    var startTime: Date
    var role: String
}

struct EmergencyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EmergencyActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner
            HStack(spacing: 16) {
                Image("kepala")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleText(context.attributes))
                        .font(.subheadline.weight(.bold))
                    Text(subtitleText(context.attributes, state: context.state))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(context.attributes.startTime, style: .timer)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
            }
            .padding(16)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(titleText(context.attributes))
                        .font(.subheadline.weight(.bold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startTime, style: .timer)
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                }
            } compactLeading: {
                Image("kepala")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            } compactTrailing: {
                Text(context.attributes.startTime, style: .timer)
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .frame(width: 42)
            } minimal: {
                Image("kepala")
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
            }
        }
    }

    private func titleText(_ attrs: EmergencyActivityAttributes) -> String {
        attrs.role == "emergencyContact"
            ? "\(attrs.userName) needs help"
            : "Emergency Active"
    }

    private func subtitleText(_ attrs: EmergencyActivityAttributes, state: EmergencyActivityAttributes.ContentState) -> String {
        attrs.role == "emergencyContact"
            ? statusLabel(state.status)
            : "\(state.contactsNotified) contact(s) notified"
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "OnTheWay": return "On the way to safe place"
        case "Urgent": return "SOS — Needs immediate help"
        case "Arrived": return "Arrived safely"
        default: return "Active"
        }
    }
}

// MARK: - Active User Previews

#Preview("Lock Screen — Active User", as: .content, using: EmergencyActivityAttributes(userName: "Feivel", sessionId: "preview-123", startTime: .now, role: "activeUser")) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "active", contactsNotified: 2)
}

#Preview("Compact — Active User", as: .dynamicIsland(.compact), using: EmergencyActivityAttributes(userName: "Feivel", sessionId: "preview-123", startTime: .now, role: "activeUser")) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "active", contactsNotified: 2)
}

#Preview("Expanded — Active User", as: .dynamicIsland(.expanded), using: EmergencyActivityAttributes(userName: "Feivel", sessionId: "preview-123", startTime: .now, role: "activeUser")) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "active", contactsNotified: 2)
}

// MARK: - Emergency Contact Previews

#Preview("Lock Screen — Contact", as: .content, using: EmergencyActivityAttributes(userName: "Maya", sessionId: "preview-456", startTime: .now, role: "emergencyContact")) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "OnTheWay", contactsNotified: 0)
    EmergencyActivityAttributes.ContentState(status: "Urgent", contactsNotified: 0)
}

#Preview("Compact — Contact", as: .dynamicIsland(.compact), using: EmergencyActivityAttributes(userName: "Maya", sessionId: "preview-456", startTime: .now, role: "emergencyContact")) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "OnTheWay", contactsNotified: 0)
}

#Preview("Expanded — Contact", as: .dynamicIsland(.expanded), using: EmergencyActivityAttributes(userName: "Maya", sessionId: "preview-456", startTime: .now, role: "emergencyContact")) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "Urgent", contactsNotified: 0)
}
