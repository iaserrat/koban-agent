import Foundation

struct SyncEventRequest: Codable, Hashable {
    var eventID: String
    var deviceID: String
    var localSequence: Int64
    var surface: MonitoredSurface
    var kind: ChangeKind
    var observedAt: String
    var collectedAt: String
    var payloadHash: String
    var payload: Data

    private enum CodingKeys: String, CodingKey {
        case eventID = "eventId"
        case deviceID = "deviceId"
        case localSequence
        case surface
        case kind
        case observedAt
        case collectedAt
        case payloadHash
        case payload
    }
}
