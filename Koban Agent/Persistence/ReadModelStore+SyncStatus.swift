import Foundation
import GRDB

extension ReadModelStore {
    /// The sensor's upload state, read alongside the rest of the published snapshot. Sync is off
    /// unless it is both enabled and bound to a device; otherwise the outbox is counted by state so
    /// the glance can show a backlog, a stuck upload, or when it last drained.
    func syncStatus(in db: Database, enabled: Bool, deviceID: String?) throws -> SyncStatus {
        guard enabled, let deviceID else { return .disabled }
        let mine = SyncOutboxEvent.filter(Column(StorageColumns.deviceID) == deviceID)
        let pending = try mine
            .filter([SyncEventState.pending.rawValue, SyncEventState.inFlight.rawValue]
                .contains(Column(StorageColumns.state)))
            .fetchCount(db)
        let failed = try mine
            .filter(Column(StorageColumns.state) == SyncEventState.poison.rawValue)
            .fetchCount(db)
        let lastSyncedAt = try Date.fetchOne(
            db,
            sql: """
            SELECT MAX(\(StorageColumns.updatedAt))
            FROM \(SyncOutboxEvent.databaseTableName)
            WHERE \(StorageColumns.deviceID) = ? AND \(StorageColumns.state) = ?
            """,
            arguments: [deviceID, SyncEventState.acked.rawValue]
        )
        return SyncStatus(
            isEnabled: true,
            pendingCount: pending,
            failedCount: failed,
            lastSyncedAt: lastSyncedAt
        )
    }
}
