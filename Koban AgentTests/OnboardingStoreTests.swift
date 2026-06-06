import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - OnboardingStoreTests

struct OnboardingStoreTests {
    @Test
    func freshDatabaseReadsAsFirstRun() throws {
        let store = try OnboardingStore(database: AppDatabase(DatabaseQueue()))

        #expect(try store.isComplete() == false)
    }

    @Test
    func markCompleteSetsTheFlag() throws {
        let store = try OnboardingStore(database: AppDatabase(DatabaseQueue()))

        try store.markComplete(at: Date(timeIntervalSince1970: 1))

        #expect(try store.isComplete())
    }

    @Test
    func markCompleteStaysASingleFact() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = OnboardingStore(database: database)

        try store.markComplete(at: Date(timeIntervalSince1970: 1))
        try store.markComplete(at: Date(timeIntervalSince1970: 2))

        let rowCount = try database.reader.read { db in
            try OnboardingState.fetchCount(db)
        }
        #expect(rowCount == 1)
    }
}
