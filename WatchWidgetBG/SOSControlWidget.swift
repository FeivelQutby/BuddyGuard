//
//  SOSControlWidget.swift
//  BuddyGuard
//
//  Created by Benedicta Joyce Sutandyo on 09/07/26.
//

import SwiftUI
import WidgetKit


struct SOSControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.buddyguard.sos") {
            ControlWidgetButton(action: OpenSOSIntent()){
                Label("SOS", systemImage: "sos").labelStyle(.iconOnly)
            }
        }
        .displayName("BuddyGuard SOS")
    }
}
