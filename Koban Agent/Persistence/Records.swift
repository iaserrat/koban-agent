import GRDB

// MARK: - MonitoredSurface + DatabaseValueConvertible

// GRDB conformances live here, not on the domain types, so `Model/` stays persistence-free.
// The structs are `Codable`, so GRDB derives column mapping automatically (nested `Provenance`
// is stored as JSON). String-backed enums become their raw value via `DatabaseValueConvertible`.

extension MonitoredSurface: DatabaseValueConvertible {}

// MARK: - Severity + DatabaseValueConvertible

extension Severity: DatabaseValueConvertible {}

// MARK: - ChangeKind + DatabaseValueConvertible

extension ChangeKind: DatabaseValueConvertible {}

// MARK: - SurfaceHealthState + DatabaseValueConvertible

extension SurfaceHealthState: DatabaseValueConvertible {}

// MARK: - SyncEventState + DatabaseValueConvertible

extension SyncEventState: DatabaseValueConvertible {}

// MARK: - InventoryItem + FetchableRecord, PersistableRecord

extension InventoryItem: FetchableRecord, PersistableRecord {
    static let databaseTableName = "inventoryItem"
}

// MARK: - ChangeEvent + FetchableRecord, PersistableRecord

extension ChangeEvent: FetchableRecord, PersistableRecord {
    static let databaseTableName = "changeEvent"
}

// MARK: - Finding + FetchableRecord, PersistableRecord

extension Finding: FetchableRecord, PersistableRecord {
    static let databaseTableName = "finding"
}

// MARK: - SurfaceHealth + FetchableRecord, PersistableRecord

extension SurfaceHealth: FetchableRecord, PersistableRecord {
    static let databaseTableName = "surfaceHealth"
}

// MARK: - SyncOutboxEvent + FetchableRecord, PersistableRecord

extension SyncOutboxEvent: FetchableRecord, PersistableRecord {
    static let databaseTableName = "syncOutboxEvent"
}

// MARK: - OnboardingState + FetchableRecord, PersistableRecord

extension OnboardingState: FetchableRecord, PersistableRecord {
    static let databaseTableName = "onboarding"
}
