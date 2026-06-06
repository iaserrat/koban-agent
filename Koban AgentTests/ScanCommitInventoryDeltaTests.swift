import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - ScanCommitInventoryDeltaTests

struct ScanCommitInventoryDeltaTests {
    @Test
    func commitScanWritesOnlyInventoryDelta() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database)
        let inventory = InventoryRepository(database: database)
        let unchanged = Fixture.item(surface: .homebrew, name: "unchanged")
        let removed = Fixture.item(surface: .homebrew, name: "removed")
        let modified = Fixture.item(surface: .homebrew, name: "modified", version: "1")
        let updated = Fixture.item(surface: .homebrew, name: "modified", version: "2")
        let added = Fixture.item(surface: .homebrew, name: "added")
        let completedAt = Date(timeIntervalSince1970: 6)

        try inventory.replace([unchanged, removed, modified], for: .homebrew)
        try installInventoryAuditTriggers(in: database)

        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [unchanged, removed, modified],
            current: [unchanged, updated, added],
            events: [],
            findings: [],
            durationMilliseconds: 20,
            completedAt: completedAt
        ))

        let audit = try inventoryAudit(in: database)
        #expect(audit.inserted == 1)
        #expect(audit.updated == 1)
        #expect(audit.deleted == 1)
        #expect(try inventory.snapshot(for: .homebrew) == [added, updated, unchanged])
    }

    private func installInventoryAuditTriggers(in database: AppDatabase) throws {
        try database.writer.write { db in
            try db.create(table: InventoryAuditNames.table) { table in
                table.column(InventoryAuditNames.actionColumn, .text).notNull()
            }
            try db.execute(sql: InventoryAuditSQL.insertTrigger)
            try db.execute(sql: InventoryAuditSQL.updateTrigger)
            try db.execute(sql: InventoryAuditSQL.deleteTrigger)
        }
    }

    private func inventoryAudit(in database: AppDatabase) throws -> InventoryAudit {
        try database.reader.read { db in
            let rows = try Row.fetchAll(db, sql: InventoryAuditSQL.counts)
            var counts = InventoryAudit()
            for row in rows {
                let action: String = row[InventoryAuditNames.actionColumn]
                let count: Int = row[InventoryAuditNames.countColumn]
                counts.record(action: action, count: count)
            }
            return counts
        }
    }
}

// MARK: - InventoryAuditNames

private enum InventoryAuditNames {
    static let table = "inventoryAudit"
    static let actionColumn = "action"
    static let countColumn = "count"
    static let insertAction = "insert"
    static let updateAction = "update"
    static let deleteAction = "delete"
}

// MARK: - InventoryAuditSQL

private enum InventoryAuditSQL {
    static let insertTrigger = """
    CREATE TRIGGER inventory_audit_insert AFTER INSERT ON inventoryItem
    BEGIN
        INSERT INTO inventoryAudit (action) VALUES ('insert');
    END
    """

    static let updateTrigger = """
    CREATE TRIGGER inventory_audit_update AFTER UPDATE ON inventoryItem
    BEGIN
        INSERT INTO inventoryAudit (action) VALUES ('update');
    END
    """

    static let deleteTrigger = """
    CREATE TRIGGER inventory_audit_delete AFTER DELETE ON inventoryItem
    BEGIN
        INSERT INTO inventoryAudit (action) VALUES ('delete');
    END
    """

    static let counts = """
    SELECT action, COUNT(*) AS count
    FROM inventoryAudit
    GROUP BY action
    """
}

// MARK: - InventoryAudit

private struct InventoryAudit {
    var inserted = 0
    var updated = 0
    var deleted = 0

    mutating func record(action: String, count: Int) {
        switch action {
        case InventoryAuditNames.insertAction:
            inserted = count
        case InventoryAuditNames.updateAction:
            updated = count
        case InventoryAuditNames.deleteAction:
            deleted = count
        default:
            break
        }
    }
}
