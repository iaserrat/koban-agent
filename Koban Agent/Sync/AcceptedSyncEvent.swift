import Foundation

struct AcceptedSyncEvent: Codable, Hashable {
    var eventID: String
    var localSequence: Int64
    var duplicate: Bool

    private enum CodingKeys: String, CodingKey {
        case eventID = "eventId"
        case localSequence
        case duplicate
    }
}
