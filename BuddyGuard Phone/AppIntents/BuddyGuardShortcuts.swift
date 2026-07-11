import AppIntents

struct BuddyGuardShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerEmergencyIntent(),
            phrases: [
                "Trigger emergency with \(.applicationName)",
                "I need help \(.applicationName)",
                "Start emergency \(.applicationName)",
                "SOS \(.applicationName)"
            ],
            shortTitle: "Trigger Emergency",
            systemImageName: "sos"
        )
    }
}
