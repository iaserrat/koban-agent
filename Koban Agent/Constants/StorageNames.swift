import Foundation

/// On-disk storage identifiers: the Application Support subdirectory, database file, and
/// migration/table names that are not tied to a domain type. The single home for these
/// literals (see CLAUDE.md).
enum StorageNames {
    static let directory = "Koban Agent"
    static let databaseFile = "koban.sqlite"
    /// Sidecar files SQLite keeps alongside the database in WAL mode. Removed together with the
    /// main file when recreating after corruption so no stale journal survives.
    static let databaseSidecarSuffixes = ["-wal", "-shm"]
    static let initialMigration = "v1"
    static let baselineTable = "surfaceBaseline"
    static let inventorySearchTable = "inventorySearch"
    static let changeEventTimestampIndex = "changeEventTimestampIndex"
    static let changeEventItemTimestampIndex = "changeEventItemTimestampIndex"
    static let findingTimestampIndex = "findingTimestampIndex"
    static let findingItemTimestampIndex = "findingItemTimestampIndex"
    static let inventorySurfaceNamePathKindIndex = "inventorySurfaceNamePathKindIndex"
    static let syncOutboxDeviceSequenceIndex = "syncOutboxDeviceSequenceIndex"
    static let syncOutboxStateAttemptIndex = "syncOutboxStateAttemptIndex"
    static let createInventorySurfaceNamePathKindIndex = """
    CREATE INDEX \(inventorySurfaceNamePathKindIndex)
    ON \(InventoryItem.databaseTableName)(
        surface,
        name COLLATE NOCASE,
        path COLLATE NOCASE,
        kind
    )
    """
    static let createInventorySearchTable = """
    CREATE VIRTUAL TABLE \(inventorySearchTable) USING fts5(
        searchText,
        content = '\(InventoryItem.databaseTableName)',
        content_rowid = '\(StorageColumns.rowID)',
        tokenize = 'unicode61'
    )
    """
    static let createSyncOutboxDeviceSequenceIndex = """
    CREATE UNIQUE INDEX \(syncOutboxDeviceSequenceIndex)
    ON \(SyncOutboxEvent.databaseTableName)(
        \(StorageColumns.deviceID),
        \(StorageColumns.localSequence)
    )
    """
    static let createSyncOutboxStateAttemptIndex = """
    CREATE INDEX \(syncOutboxStateAttemptIndex)
    ON \(SyncOutboxEvent.databaseTableName)(
        \(StorageColumns.state),
        \(StorageColumns.nextAttemptAt),
        \(StorageColumns.localSequence)
    )
    """
}
