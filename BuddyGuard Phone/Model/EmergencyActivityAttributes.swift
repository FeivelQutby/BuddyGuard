import Foundation
import ActivityKit

struct EmergencyActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        var status: String
        var contactsNotified: Int
    }

    var userName: String
    var sessionId: String
    var startTime: Date
    var role: String
}
