import WidgetKit
import SwiftUI

@main
struct IOSWidgetBundle: WidgetBundle {
    var body: some Widget {
        EmergencyLiveActivity()
        EmergencyControl()
    }
}
