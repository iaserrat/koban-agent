import GRDB

// MARK: - StorageRetentionPolicy

struct StorageRetentionPolicy: Hashable {
    let maxStoredEvents: Int
    let maxStoredFindings: Int

    init(settings: PersistenceSettings) {
        maxStoredEvents = settings.maxStoredEvents
        maxStoredFindings = settings.maxStoredFindings
    }

    func apply(in db: Database) throws {
        try prune(sql: RetentionQueries.pruneChangeEvents, limit: maxStoredEvents, in: db)
        try prune(sql: RetentionQueries.pruneFindings, limit: maxStoredFindings, in: db)
    }

    private func prune(sql: String, limit: Int, in db: Database) throws {
        guard limit >= Self.minimumStoredRows else { return }
        try db.execute(sql: sql, arguments: [limit])
    }
}

// MARK: - StorageRetentionPolicy + Constants

extension StorageRetentionPolicy {
    static let minimumStoredRows = 0
}
