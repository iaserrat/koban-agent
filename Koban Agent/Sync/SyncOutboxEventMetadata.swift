import Foundation

struct SyncOutboxEventMetadata {
    var identity: SyncOutboxIdentity
    var localSequence: Int64
    var surface: MonitoredSurface
    var kind: ChangeKind
    var observedAt: Date
    var collectedAt: Date
}
