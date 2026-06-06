import Foundation
import GRDB
import OSLog

// MARK: - AppDatabase

/// Owns the SQLite connection and schema. The store lives under Application Support so it
/// survives launches and can later feed the fleet control center. Opening runs migrations.
struct AppDatabase {
    let reader: any DatabaseReader
    let writer: any DatabaseWriter

    init(_ storage: any DatabaseReader & DatabaseWriter) throws {
        reader = storage
        writer = storage
        try Self.migrator.migrate(storage)
    }

    /// Opens the on-disk database at `~/Library/Application Support/Koban Agent/koban.sqlite`,
    /// creating the directory if needed.
    static func live() throws -> Self {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appending(component: StorageNames.directory, directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(component: StorageNames.databaseFile)
        return try openRecoveringFromCorruption(at: url)
    }

    static func open(at url: URL) throws -> Self {
        let pool = try DatabasePool(path: url.path, configuration: liveConfiguration)
        return try Self(pool)
    }

    /// Opens the database, recreating it from scratch if the existing file is corrupt. The
    /// store is a materialised view of on-disk state, not the source of truth, so a corrupt
    /// file is safe to discard and rebuild on the next scan rather than wedging the agent.
    /// Only corruption-class failures trigger recreation; any other error (a permissions or
    /// disk problem) is surfaced so it is not masked by a destructive retry.
    static func openRecoveringFromCorruption(at url: URL) throws -> Self {
        do {
            return try open(at: url)
        } catch let error where isCorruption(error) {
            Log.persistence.error(
                "Database at \(url.path, privacy: .public) is corrupt (\(error)); recreating it."
            )
            try removeDatabaseFiles(at: url)
            return try open(at: url)
        }
    }

    private static func isCorruption(_ error: any Error) -> Bool {
        guard let databaseError = error as? DatabaseError else { return false }
        return [.SQLITE_CORRUPT, .SQLITE_NOTADB].contains(databaseError.resultCode.primaryResultCode)
    }

    private static func removeDatabaseFiles(at url: URL) throws {
        let fileManager = FileManager.default
        for suffix in [""] + StorageNames.databaseSidecarSuffixes {
            let fileURL = URL(fileURLWithPath: url.path + suffix)
            guard fileManager.fileExists(atPath: fileURL.path) else { continue }
            try fileManager.removeItem(at: fileURL)
        }
    }

    func checkpointForShutdown() throws {
        _ = try writer.writeWithoutTransaction { db in
            try db.checkpoint(.truncate)
        }
    }

    private static var liveConfiguration: Configuration {
        var configuration = Configuration()
        configuration.busyMode = .timeout(DatabaseRuntimeDefaults.busyTimeoutSeconds)
        configuration.maximumReaderCount = DatabaseRuntimeDefaults.maximumReaderCount
        configuration.prepareDatabase { db in
            try db.execute(sql: DatabaseRuntimeQueries.synchronousNormal)
        }
        return configuration
    }
}

extension AppDatabase {
    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration(StorageNames.initialMigration) { db in
            try db.create(table: InventoryItem.databaseTableName) { table in
                table.column(StorageColumns.surface, .text).notNull()
                table.column(StorageColumns.kind, .text).notNull()
                table.column(StorageColumns.name, .text).notNull()
                table.column("version", .text)
                table.column(StorageColumns.path, .text).notNull()
                table.column("provenance", .text).notNull()
                table.primaryKey([
                    StorageColumns.surface,
                    StorageColumns.kind,
                    StorageColumns.path,
                    StorageColumns.name
                ])
            }
            try db.create(table: ChangeEvent.databaseTableName) { table in
                table.primaryKey("id", .text)
                table.column("timestamp", .datetime).notNull()
                table.column(StorageColumns.surface, .text).notNull()
                table.column(StorageColumns.kind, .text).notNull()
                table.column("itemID", .text).notNull()
                table.column("itemName", .text).notNull()
                table.column("detail", .text).notNull()
            }
            try db.create(table: Finding.databaseTableName) { table in
                table.primaryKey("id", .text)
                table.column("timestamp", .datetime).notNull()
                table.column("surface", .text).notNull()
                table.column("itemID", .text).notNull()
                table.column("ruleID", .text).notNull()
                table.column("title", .text).notNull()
                table.column("rationale", .text).notNull()
                table.column("severity", .text).notNull()
                table.column("itemName", .text).notNull()
                table.column("evidence", .text).notNull()
            }
            try db.create(table: StorageNames.baselineTable) { table in
                table.primaryKey("surface", .text)
            }
            try db.create(table: SurfaceHealth.databaseTableName) { table in
                table.primaryKey("surface", .text)
                table.column("state", .text).notNull()
                table.column("lastScanStartedAt", .datetime)
                table.column("lastScanCompletedAt", .datetime)
                table.column("lastSuccessfulScanAt", .datetime)
                table.column("lastFailure", .text)
                table.column("lastWatchIssue", .text)
                table.column("lastWatchIssueAt", .datetime)
                table.column("lastScanDurationMilliseconds", .double)
                table.column("itemCount", .integer).notNull()
                table.column(StorageColumns.lastScanEventCount, .integer).notNull()
                table.column(StorageColumns.lastScanFindingCount, .integer).notNull()
                table.column(StorageColumns.lastScanIssueCount, .integer).notNull()
                table.column(StorageColumns.lastScanAddedItemCount, .integer).notNull()
                table.column(StorageColumns.lastScanModifiedItemCount, .integer).notNull()
                table.column(StorageColumns.lastScanRemovedItemCount, .integer).notNull()
                table.column("watchPathCount", .integer).notNull()
            }
            try db.create(table: OnboardingState.databaseTableName) { table in
                table.column(StorageColumns.completedAt, .datetime).notNull()
            }
            try db.create(table: SyncOutboxEvent.databaseTableName) { table in
                table.primaryKey("id", .text)
                table.column(StorageColumns.tenantID, .text)
                table.column(StorageColumns.deviceID, .text).notNull()
                table.column(StorageColumns.localSequence, .integer).notNull()
                table.column(StorageColumns.schemaVersion, .integer).notNull()
                table.column(StorageColumns.surface, .text).notNull()
                table.column(StorageColumns.kind, .text).notNull()
                table.column(StorageColumns.observedAt, .datetime).notNull()
                table.column(StorageColumns.collectedAt, .datetime).notNull()
                table.column(StorageColumns.payload, .blob).notNull()
                table.column(StorageColumns.payloadHash, .text).notNull()
                table.column(StorageColumns.state, .text).notNull()
                table.column(StorageColumns.attemptCount, .integer).notNull()
                table.column(StorageColumns.nextAttemptAt, .datetime)
                table.column(StorageColumns.createdAt, .datetime).notNull()
                table.column(StorageColumns.updatedAt, .datetime).notNull()
            }
            try db.create(
                index: StorageNames.changeEventTimestampIndex,
                on: ChangeEvent.databaseTableName,
                columns: ["timestamp", "id"]
            )
            try db.create(
                index: StorageNames.changeEventItemTimestampIndex,
                on: ChangeEvent.databaseTableName,
                columns: ["surface", "itemID", "timestamp", "id"]
            )
            try db.create(
                index: StorageNames.findingTimestampIndex,
                on: Finding.databaseTableName,
                columns: ["timestamp", "id"]
            )
            try db.create(
                index: StorageNames.findingItemTimestampIndex,
                on: Finding.databaseTableName,
                columns: ["surface", "itemID", "timestamp", "id"]
            )
            try db.execute(sql: StorageNames.createInventorySurfaceNamePathKindIndex)
            try db.execute(sql: StorageNames.createSyncOutboxDeviceSequenceIndex)
            try db.execute(sql: StorageNames.createSyncOutboxStateAttemptIndex)
            try db.execute(sql: StorageNames.createInventorySearchTable)
            for statement in InventorySearchTriggerQueries.allCreateStatements {
                try db.execute(sql: statement)
            }
        }
        return migrator
    }
}
