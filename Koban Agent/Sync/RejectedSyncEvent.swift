import Foundation

struct RejectedSyncEvent: Codable, Hashable {
    var eventID: String
    var localSequence: Int64
    var code: String
    var message: String

    private enum CodingKeys: String, CodingKey {
        case eventID = "eventId"
        case localSequence
        case code
        case message
    }
}
