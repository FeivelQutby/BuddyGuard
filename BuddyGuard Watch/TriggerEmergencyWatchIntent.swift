//
//  TriggerEmergencyWatchIntent.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by George Maximillian Theodore on 13/07/26.
//

import AppIntents

/// Siri intent for the Apple Watch — mirrors the iOS `TriggerEmergencyIntent`.
/// Say "Trigger emergency on BuddyGuard" to activate emergency mode on the Watch.
struct TriggerEmergencyWatchIntent: AppIntent {
    static var title: LocalizedStringResource = "Trigger Emergency"
    static var description = IntentDescription(
        "Activates BuddyGuard emergency mode on Apple Watch — starts navigation to the nearest safe place and notifies your trusted contacts.",
        categoryName: "Safety"
    )
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        WatchAppState.shared.shouldTriggerEmergency = true
        return .result()
    }
}
