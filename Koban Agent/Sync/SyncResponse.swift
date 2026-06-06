import Foundation

struct SyncResponse: Codable, Hashable {
    var acceptedThroughLocalSequence: Int64
    var acceptedEvents: [AcceptedSyncEvent]
    var rejectedEvents: [RejectedSyncEvent]
    var serverTime: String
    var configGeneration: String
    var configUpdateAvailable: Bool
    var fullResnapshotRequested: Bool
    var retryAfterSeconds: UInt32
    var maxBatchBytes: UInt32
    var maxBatchEvents: UInt32
}
