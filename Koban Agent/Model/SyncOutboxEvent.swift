import Foundation

struct SyncOutboxEvent: Codable, Hashable, Identifiable {
    var id: UUID
    var tenantID: String?
    var deviceID: String
    var localSequence: Int64
    var schemaVersion: Int
    var surface: MonitoredSurface
    var kind: ChangeKind
    var observedAt: Date
    var collectedAt: Date
    var payload: Data
    var payloadHash: String
    var state: SyncEventState
    var attemptCount: Int
    var nextAttemptAt: Date?
    var createdAt: Date
    var updatedAt: Date
}
