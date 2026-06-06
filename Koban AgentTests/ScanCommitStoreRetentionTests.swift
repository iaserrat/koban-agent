import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - ScanCommitStoreRetentionTests

struct ScanCommitStoreRetentionTests {
    @Test
    func commitScanPrunesHistoryInsideCommitTransaction() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(
            database: database,
            retention: StorageRetentionPolicy(settings: PersistenceSettings(
                maxStoredEvents: 2,
                maxStoredFindings: 1
            ))
        )
        let events = EventStore(database: database)
        let item = Fixture.item(surface: .homebrew, name: "ripgrep")
        let old = Date(timeIntervalSince1970: 1)
        let middle = Date(timeIntervalSince1970: 2)
        let new = Date(timeIntervalSince1970: 3)

        try events.append(events: [
            Fixture.event(surface: .homebrew, itemName: "old", timestamp: old),
            Fixture.event(surface: .homebrew, itemName: "middle", timestamp: middle)
        ])
        try events.append(findings: [
            Fixture.finding(surface: .homebrew, itemName: "old", timestamp: old)
        ])

        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [],
            current: [item],
            events: [Fixture.event(surface: .homebrew, itemName: "new", timestamp: new)],
            findings: [Fixture.finding(surface: .homebrew, itemName: "new", timestamp: new)],
            durationMilliseconds: 20,
            completedAt: new
        ))

        #expect(try events.allEvents().map(\.itemName) == ["new", "middle"])
        #expect(try events.allFindings().map(\.itemName) == ["new"])
    }

    @Test
    func zeroRetentionLimitRemovesAllHistory() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(
            database: database,
            retention: StorageRetentionPolicy(settings: PersistenceSettings(
                maxStoredEvents: 0,
                maxStoredFindings: 0
            ))
        )
        let events = EventStore(database: database)
        let item = Fixture.item(surface: .homebrew, name: "ripgrep")
        let completedAt = Date(timeIntervalSince1970: 1)

        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [],
            current: [item],
            events: [Fixture.event(surface: .homebrew, itemName: "ripgrep", timestamp: completedAt)],
            findings: [Fixture.finding(surface: .homebrew, itemName: "ripgrep", timestamp: completedAt)],
            durationMilliseconds: 20,
            completedAt: completedAt
        ))

        #expect(try events.allEvents().isEmpty)
        #expect(try events.allFindings().isEmpty)
    }
}
