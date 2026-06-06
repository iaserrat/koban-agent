import Foundation
import GRDB

extension ScanCommitStore {
    func enqueueSyncEvents(for commit: ScanCommit, findings: [Finding], in db: Database) throws {
        guard syncSettings.enabled, let deviceID = syncSettings.deviceID else { return }

        let identity = SyncOutboxIdentity(tenantID: syncSettings.tenantID, deviceID: deviceID)
        let previousByID = Dictionary(uniqueKeysWithValues: commit.previous.map { ($0.id, $0) })
        let currentByID = Dictionary(uniqueKeysWithValues: commit.current.map { ($0.id, $0) })
        var localSequence = try nextLocalSequence(deviceID: deviceID, in: db)

        for event in commit.events {
            let item = item(for: event, previousByID: previousByID, currentByID: currentByID)
            guard let item else {
                throw SyncOutboxBuildError.missingInventoryItem(event.itemID)
            }
            try SyncOutboxEventFactory.inventoryEvent(
                metadata: SyncOutboxEventMetadata(
                    identity: identity,
                    localSequence: localSequence,
                    surface: event.surface,
                    kind: event.kind,
                    observedAt: event.timestamp,
                    collectedAt: commit.completedAt
                ),
                item: item
            )
            .insert(db)
            localSequence += 1
        }

        for finding in findings {
            try SyncOutboxEventFactory.findingEvent(
                identity: identity,
                finding: finding,
                localSequence: localSequence,
                collectedAt: commit.completedAt
            )
            .insert(db)
            localSequence += 1
        }
    }

    /// Enqueues a freshly baselined surface's full inventory as `added` events. The local activity
    /// feed deliberately omits these (a first scan is a baseline, not a flood of "added" rows), but
    /// the sync outbox needs them: the backend has no other way to learn the baseline inventory.
    func enqueueBaselineSyncEvents(
        surface: MonitoredSurface,
        items: [InventoryItem],
        findings: [Finding],
        collectedAt: Date,
        in db: Database
    ) throws {
        guard syncSettings.enabled, let deviceID = syncSettings.deviceID else { return }

        let identity = SyncOutboxIdentity(tenantID: syncSettings.tenantID, deviceID: deviceID)
        var localSequence = try nextLocalSequence(deviceID: deviceID, in: db)

        for item in items {
            try SyncOutboxEventFactory.inventoryEvent(
                metadata: SyncOutboxEventMetadata(
                    identity: identity,
                    localSequence: localSequence,
                    surface: surface,
                    kind: .added,
                    observedAt: collectedAt,
                    collectedAt: collectedAt
                ),
                item: item
            )
            .insert(db)
            localSequence += 1
        }

        for finding in findings {
            try SyncOutboxEventFactory.findingEvent(
                identity: identity,
                finding: finding,
                localSequence: localSequence,
                collectedAt: collectedAt
            )
            .insert(db)
            localSequence += 1
        }
    }

    func item(
        for event: ChangeEvent,
        previousByID: [InventoryItem.ID: InventoryItem],
        currentByID: [InventoryItem.ID: InventoryItem]
    ) -> InventoryItem? {
        switch event.kind {
        case .removed:
            previousByID[event.itemID]
        case .added, .modified:
            currentByID[event.itemID] ?? previousByID[event.itemID]
        }
    }

    func nextLocalSequence(deviceID: String, in db: Database) throws -> Int64 {
        let maxSequence = try Int64.fetchOne(
            db,
            sql: """
            SELECT MAX(\(StorageColumns.localSequence))
            FROM \(SyncOutboxEvent.databaseTableName)
            WHERE \(StorageColumns.deviceID) = ?
            """,
            arguments: [deviceID]
        ) ?? 0
        return maxSequence + 1
    }
}
