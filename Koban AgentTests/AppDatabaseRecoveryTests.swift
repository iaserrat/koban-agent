import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - AppDatabaseRecoveryTests

/// Corruption and recovery gate for the persistence boundary. The store is a rebuildable
/// cache of on-disk state, so a corrupt file is discarded and recreated rather than wedging
/// the agent; non-corruption failures are surfaced, and write transactions never partially
/// commit.
struct AppDatabaseRecoveryTests {
    @Test
    func openThrowsOnInvalidDatabaseFile() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(component: StorageNames.databaseFile)
            try Data("this is not a sqlite database".utf8).write(to: url)

            #expect(throws: (any Error).self) {
                _ = try AppDatabase.open(at: url)
            }
        }
    }

    @Test
    func recoveryRecreatesSchemaFromCorruptFile() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(component: StorageNames.databaseFile)
            try Data("corrupt".utf8).write(to: url)

            let database = try AppDatabase.openRecoveringFromCorruption(at: url)

            // The recreated database has the full schema and accepts writes again.
            try database.writer.write { db in
                try Fixture.item(name: "ripgrep").insert(db)
            }
            let count = try database.reader.read { db in
                try InventoryItem.fetchCount(db)
            }
            #expect(count == 1)
        }
    }

    @Test
    func recoveryPreservesAValidDatabase() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(component: StorageNames.databaseFile)

            let original = try AppDatabase.open(at: url)
            try original.writer.write { db in
                try Fixture.item(name: "kept").insert(db)
            }
            try original.checkpointForShutdown()

            // A valid file is never recreated, so the existing inventory survives reopen.
            let reopened = try AppDatabase.openRecoveringFromCorruption(at: url)
            let names = try reopened.reader.read { db in
                try InventoryItem.fetchAll(db).map(\.name)
            }
            #expect(names == ["kept"])
        }
    }

    @Test
    func recoveryRethrowsNonCorruptionFailures() async {
        await Fixture.withTemporaryDirectory { directory in
            // Pointing the database at an existing directory is a cantopen failure, not
            // corruption: it must surface rather than trigger a destructive recreate.
            #expect(throws: (any Error).self) {
                _ = try AppDatabase.openRecoveringFromCorruption(at: directory)
            }
            #expect(FileManager.default.fileExists(atPath: directory.path))
        }
    }

    @Test
    func failedWriteTransactionRollsBackCompletely() throws {
        let database = try AppDatabase(DatabaseQueue())

        try? database.writer.write { db in
            try Fixture.item(name: "doomed").insert(db)
            throw RecoveryTestError.aborted
        }

        let count = try database.reader.read { db in
            try InventoryItem.fetchCount(db)
        }
        #expect(count == 0)
    }
}

// MARK: - RecoveryTestError

private enum RecoveryTestError: Error {
    case aborted
}
