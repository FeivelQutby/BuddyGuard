import ActivityKit
import WidgetKit
import SwiftUI

struct EmergencyActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        var status: String
        var contactsNotified: Int
    }

    var userName: String
    var sessionId: String
    var startTime: Date
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
                    Text("Emergency Active")
                        .font(.subheadline.weight(.bold))
                    Text("\(context.state.contactsNotified) contact(s) notified")
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
                    Image(systemName: "sos")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.red)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startTime, style: .timer)
                        .font(.headline.weight(.bold))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Emergency Active")
                        .font(.subheadline.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(context.state.contactsNotified) contact(s) notified")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "sos")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
            } compactTrailing: {
                Text(context.attributes.startTime, style: .timer)
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "sos")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview("Lock Screen", as: .content, using: EmergencyActivityAttributes(userName: "Feivel", sessionId: "preview-123", startTime: .now)) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "active", contactsNotified: 2)
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: EmergencyActivityAttributes(userName: "Feivel", sessionId: "preview-123", startTime: .now)) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "active", contactsNotified: 2)
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: EmergencyActivityAttributes(userName: "Feivel", sessionId: "preview-123", startTime: .now)) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "active", contactsNotified: 2)
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: EmergencyActivityAttributes(userName: "Feivel", sessionId: "preview-123", startTime: .now)) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "active", contactsNotified: 2)
}
