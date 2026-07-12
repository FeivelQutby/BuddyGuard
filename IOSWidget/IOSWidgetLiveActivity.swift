import ActivityKit
import WidgetKit
import SwiftUI

struct EmergencyActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var elapsedSeconds: Int
        var contactsNotified: Int
    }

    var userName: String
    var sessionId: String
}

struct EmergencyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EmergencyActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner
            HStack(spacing: 16) {
                Image(systemName: "sos")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.red))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency Active")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(context.state.contactsNotified) contact(s) notified")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Text(formattedTime(context.state.elapsedSeconds))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(16)
            .activityBackgroundTint(Color(red: 0x61/255, green: 0x55/255, blue: 0xF5/255))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "sos")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.red)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formattedTime(context.state.elapsedSeconds))
                        .font(.headline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Emergency Active")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(context.state.contactsNotified) contact(s) notified")
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            } compactLeading: {
                Image(systemName: "sos")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
            } compactTrailing: {
                Text(formattedTime(context.state.elapsedSeconds))
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "sos")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.red)
            }
            .keylineTint(Color(red: 0x61/255, green: 0x55/255, blue: 0xF5/255))
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview("Notification", as: .content, using: EmergencyActivityAttributes(userName: "Feivel", sessionId: "preview-123")) {
    EmergencyLiveActivity()
} contentStates: {
    EmergencyActivityAttributes.ContentState(status: "active", elapsedSeconds: 45, contactsNotified: 2)
    EmergencyActivityAttributes.ContentState(status: "active", elapsedSeconds: 180, contactsNotified: 3)
}
