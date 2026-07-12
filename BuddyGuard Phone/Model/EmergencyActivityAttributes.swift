import ActivityKit

struct EmergencyActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var elapsedSeconds: Int
        var contactsNotified: Int
    }

    var userName: String
    var sessionId: String
}
