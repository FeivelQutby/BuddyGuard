import WidgetKit
import SwiftUI

@available(iOS 18.0, *)
struct EmergencyControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.buddyguard.emergency-control") {
            ControlWidgetButton(action: TriggerEmergencyIntent()) {
                Label("Emergency", systemImage: "sos")
            }
        }
        .displayName("BuddyGuard Emergency")
        .description("Instantly trigger emergency mode.")
    }
}
