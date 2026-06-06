import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - AppDatabaseTests

struct AppDatabaseTests {
    @Test
    func initialSchemaCreatesHotPathIndexes() throws {
        let database = try AppDatabase(DatabaseQueue())
        let expectedIndexes = [
            StorageNames.changeEventTimestampIndex: ["timestamp", "id"],
            StorageNames.changeEventItemTimestampIndex: ["surface", "itemID", "timestamp", "id"],
            StorageNames.findingTimestampIndex: ["timestamp", "id"],
            StorageNames.findingItemTimestampIndex: ["surface", "itemID", "timestamp", "id"],
            StorageNames.inventorySurfaceNamePathKindIndex: ["surface", "name", "path", "kind"],
            StorageNames.syncOutboxDeviceSequenceIndex: ["deviceID", "localSequence"],
            StorageNames.syncOutboxStateAttemptIndex: ["state", "nextAttemptAt", "localSequence"]
        ]

        let indexes = try database.reader.read { db in
            var columnsByIndex: [String: [String]] = [:]
            for indexName in expectedIndexes.keys {
                columnsByIndex[indexName] = try indexColumns(indexName, in: db)
            }
            return columnsByIndex
        }

        #expect(indexes == expectedIndexes)
    }

    @Test
    func initialSchemaCreatesInventorySearchProjection() throws {
        let database = try AppDatabase(DatabaseQueue())

        let objectsExist = try database.reader.read { db in
            let names = [
                StorageNames.inventorySearchTable,
                InventorySearchTriggerQueries.insertTriggerName,
                InventorySearchTriggerQueries.updateTriggerName,
                InventorySearchTriggerQueries.deleteTriggerName
            ]
            var arguments: StatementArguments = [names.count]
            arguments += StatementArguments(names)
            return try Bool.fetchOne(
                db,
                sql: "SELECT COUNT(*) = ? FROM sqlite_master WHERE name IN (?, ?, ?, ?)",
                arguments: arguments
            ) ?? false
        }

        #expect(objectsExist)
        #expect(try searchTableColumns(in: database) == [StorageColumns.searchText])
    }

    @Test
    func inventoryWritesMaintainSearchProjection() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ReadModelStore(database: database)
        let inserted = Fixture.item(name: "triggered", detail: "oldtoken")
        let updated = Fixture.item(name: "triggered", detail: "newtoken")

        _ = try database.writer.write { db in
            try inserted.insert(db)
        }
        #expect(try searchedNames("oldtoken", using: store) == ["triggered"])

        _ = try database.writer.write { db in
            try updated.save(db)
        }
        #expect(try searchedNames("oldtoken", using: store).isEmpty)
        #expect(try searchedNames("newtoken", using: store) == ["triggered"])

        _ = try database.writer.write { db in
            try updated.delete(db)
        }
        #expect(try searchedNames("newtoken", using: store).isEmpty)
    }

    @Test
    func openUsesPoolWithWALAndRuntimeSettings() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let databaseURL = directory.appending(component: StorageNames.databaseFile)
            let database = try AppDatabase.open(at: databaseURL)
            let pool = database.writer as? DatabasePool
            let readerPool = database.reader as? DatabasePool
            let maximumReaderCount = DatabaseRuntimeDefaults.maximumReaderCount

            #expect(pool?.configuration.maximumReaderCount == maximumReaderCount)
            #expect(readerPool?.configuration.maximumReaderCount == maximumReaderCount)
            try database.reader.read { db in
                let journalMode = try String.fetchOne(db, sql: DatabaseRuntimeQueries.readJournalMode)
                let synchronous = try Int.fetchOne(db, sql: DatabaseRuntimeQueries.readSynchronous)

                #expect(journalMode == DatabaseRuntimeQueries.journalModeWal)
                #expect(synchronous == DatabaseRuntimeDefaults.synchronousNormalValue)
            }
        }
    }

    @Test
    func checkpointForShutdownTruncatesWAL() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let databaseURL = directory.appending(component: StorageNames.databaseFile)
            let walURL = directory.appending(component: StorageNames.databaseFile + "-wal")
            let database = try AppDatabase.open(at: databaseURL)

            try database.writer.write { db in
                try db.create(table: DatabaseRuntimeQueries.checkpointScratchTable) { table in
                    table.autoIncrementedPrimaryKey("id")
                    table.column("value", .text).notNull()
                }
                for index in 0 ..< 128 {
                    try db.execute(
                        sql: checkpointScratchInsertSQL,
                        arguments: [String(index)]
                    )
                }
            }

            #expect(fileSize(at: walURL) > 0)
            try database.checkpointForShutdown()
            #expect(fileSize(at: walURL) == 0)
        }
    }

    private var checkpointScratchInsertSQL: String {
        "INSERT INTO \(DatabaseRuntimeQueries.checkpointScratchTable) (value) VALUES (?)"
    }

    private func searchedNames(_ text: String, using store: ReadModelStore) throws -> [String] {
        let page = try store.inventoryPage(InventoryPageRequest(
            surface: .homebrew,
            limit: 10,
            searchText: InventorySearchText(text)
        ))
        return page.items.map(\.name)
    }

    private func indexColumns(_ indexName: String, in db: Database) throws -> [String] {
        let rows = try Row.fetchAll(db, sql: "PRAGMA index_info(\(indexName))")
        return rows.map { row in
            row["name"]
        }
    }

    private func searchTableColumns(in database: AppDatabase) throws -> [String] {
        try database.reader.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: "PRAGMA table_info(\(StorageNames.inventorySearchTable))"
            )
            return rows.map { row in
                row[StorageColumns.name]
            }
        }
    }

    private func fileSize(at url: URL) -> UInt64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber
        else { return 0 }
        return size.uint64Value
    }
}
