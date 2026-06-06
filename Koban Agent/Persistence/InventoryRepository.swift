import Foundation
import GRDB

/// Reads and writes the stored inventory snapshot per surface, and tracks whether a surface has
/// been baselined yet (so the first ever scan establishes inventory without emitting a flood of
/// "added" events).
struct InventoryRepository {
    let database: AppDatabase

    func snapshot(for surface: MonitoredSurface) throws -> [InventoryItem] {
        try database.reader.read { db in
            try InventoryItem
                .filter(Column(StorageColumns.surface) == surface)
                .order(Column(StorageColumns.name))
                .fetchAll(db)
        }
    }

    /// Replaces the entire stored snapshot for one surface in a single transaction.
    func replace(_ items: [InventoryItem], for surface: MonitoredSurface) throws {
        try database.writer.write { db in
            try InventoryItem.filter(Column(StorageColumns.surface) == surface).deleteAll(db)
            for item in items {
                try item.insert(db)
            }
        }
    }

    func isBaselined(_ surface: MonitoredSurface) throws -> Bool {
        try database.reader.read { db in
            try Bool.fetchOne(
                db,
                sql: "SELECT EXISTS(SELECT 1 FROM \(StorageNames.baselineTable) WHERE surface = ?)",
                arguments: [surface]
            ) ?? false
        }
    }

    func markBaselined(_ surface: MonitoredSurface) throws {
        try database.writer.write { db in
            try db.execute(
                sql: "INSERT OR IGNORE INTO \(StorageNames.baselineTable) (surface) VALUES (?)",
                arguments: [surface]
            )
        }
    }
}
