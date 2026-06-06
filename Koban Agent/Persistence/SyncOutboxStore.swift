import Foundation
import GRDB

struct SyncOutboxStore {
    let database: AppDatabase

    func enqueue(_ event: SyncOutboxEvent) throws {
        try database.writer.write { db in
            try event.insert(db)
        }
    }

    func nextLocalSequence(deviceID: String) throws -> Int64 {
        try database.writer.write { db in
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

    func pending(limit: Int, now: Date) throws -> [SyncOutboxEvent] {
        try database.reader.read { db in
            try SyncOutboxEvent
                .filter(Column(StorageColumns.state) == SyncEventState.pending)
                .filter(Column(StorageColumns.nextAttemptAt) == nil || Column(StorageColumns.nextAttemptAt) <=
                    now)
                .order(Column(StorageColumns.localSequence))
                .limit(limit)
                .fetchAll(db)
        }
    }

    func lastAckedLocalSequence(deviceID: String) throws -> Int64 {
        try database.reader.read { db in
            try Int64.fetchOne(
                db,
                sql: """
                SELECT MAX(\(StorageColumns.localSequence))
                FROM \(SyncOutboxEvent.databaseTableName)
                WHERE \(StorageColumns.deviceID) = ?
                AND \(StorageColumns.state) = ?
                """,
                arguments: [deviceID, SyncEventState.acked.rawValue]
            ) ?? 0
        }
    }

    func backlog(deviceID: String) throws -> SyncBacklog {
        try database.reader.read { db in
            let row = try Row.fetchOne(
                db,
                sql: """
                SELECT COUNT(*) AS \(StorageColumns.eventCount),
                COALESCE(SUM(LENGTH(\(StorageColumns.payload))), 0) AS \(StorageColumns.byteCount)
                FROM \(SyncOutboxEvent.databaseTableName)
                WHERE \(StorageColumns.deviceID) = ?
                AND \(StorageColumns.state) IN (?, ?)
                """,
                arguments: [
                    deviceID,
                    SyncEventState.pending.rawValue,
                    SyncEventState.inFlight.rawValue
                ]
            )
            return SyncBacklog(
                eventCount: row?[StorageColumns.eventCount] ?? 0,
                byteCount: row?[StorageColumns.byteCount] ?? 0
            )
        }
    }

    func markInFlight(localSequences: [Int64], at date: Date) throws {
        guard localSequences.isEmpty == false else { return }
        _ = try database.writer.write { db in
            try SyncOutboxEvent
                .filter(localSequences.contains(Column(StorageColumns.localSequence)))
                .updateAll(
                    db,
                    Column(StorageColumns.state).set(to: SyncEventState.inFlight),
                    Column(StorageColumns.updatedAt).set(to: date)
                )
        }
    }

    func markAcked(localSequences: [Int64], at date: Date) throws {
        guard localSequences.isEmpty == false else { return }
        _ = try database.writer.write { db in
            try SyncOutboxEvent
                .filter(localSequences.contains(Column(StorageColumns.localSequence)))
                .updateAll(
                    db,
                    Column(StorageColumns.state).set(to: SyncEventState.acked),
                    Column(StorageColumns.updatedAt).set(to: date)
                )
        }
    }

    func markAcked(deviceID: String, through localSequence: Int64, at date: Date) throws {
        guard localSequence > 0 else { return }
        _ = try database.writer.write { db in
            try SyncOutboxEvent
                .filter(Column(StorageColumns.deviceID) == deviceID)
                .filter(Column(StorageColumns.localSequence) <= localSequence)
                .updateAll(
                    db,
                    Column(StorageColumns.state).set(to: SyncEventState.acked),
                    Column(StorageColumns.updatedAt).set(to: date)
                )
        }
    }

    func markPoison(localSequences: [Int64], at date: Date) throws {
        guard localSequences.isEmpty == false else { return }
        _ = try database.writer.write { db in
            try SyncOutboxEvent
                .filter(localSequences.contains(Column(StorageColumns.localSequence)))
                .updateAll(
                    db,
                    Column(StorageColumns.state).set(to: SyncEventState.poison),
                    Column(StorageColumns.updatedAt).set(to: date)
                )
        }
    }

    func scheduleRetry(localSequences: [Int64], nextAttemptAt: Date, at date: Date) throws {
        guard localSequences.isEmpty == false else { return }
        _ = try database.writer.write { db in
            try SyncOutboxEvent
                .filter(localSequences.contains(Column(StorageColumns.localSequence)))
                .updateAll(
                    db,
                    Column(StorageColumns.state).set(to: SyncEventState.pending),
                    Column(StorageColumns.attemptCount).set(to: Column(StorageColumns.attemptCount) + 1),
                    Column(StorageColumns.nextAttemptAt).set(to: nextAttemptAt),
                    Column(StorageColumns.updatedAt).set(to: date)
                )
        }
    }
}
