import Foundation
import GRDB

/// Reads and writes the single onboarding-complete flag. A value-typed store over the database,
/// matching the other repositories; the engine and app delegate hold one to gate the first-run
/// flow.
struct OnboardingStore {
    let database: AppDatabase

    /// True once the user has finished onboarding. The flag is the row's presence, so a fresh
    /// database (or one reset after corruption) correctly reads as a first run.
    func isComplete() throws -> Bool {
        try database.reader.read { db in
            try OnboardingState.fetchCount(db) > 0
        }
    }

    /// Records that onboarding finished. Replaces any prior row so the table stays a single fact.
    func markComplete(at date: Date) throws {
        try database.writer.write { db in
            try OnboardingState.deleteAll(db)
            try OnboardingState(completedAt: date).insert(db)
        }
    }
}
