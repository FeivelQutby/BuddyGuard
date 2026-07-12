import AppIntents

struct TriggerEmergencyIntent: AppIntent {
    static var title: LocalizedStringResource = "Trigger Emergency"
    static var description = IntentDescription(
        "Activates BuddyGuard emergency mode — starts live location sharing with your trusted contacts.",
        categoryName: "Safety"
    )
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
