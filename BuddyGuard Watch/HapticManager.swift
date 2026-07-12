//
//  File.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Benedicta Joyce Sutandyo on 10/07/26.
//

import WatchKit

enum HapticManager {
    static func play(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
}
