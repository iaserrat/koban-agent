import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - ScanCommitStoreTests

struct ScanCommitStoreTests {
    @Test
    func commitScanPersistsInventoryEventsFindingsAndHealthAtomically() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database)
        let inventory = InventoryRepository(database: database)
        let events = EventStore(database: database)
        let health = HealthStore(database: database)
        let completedAt = Date(timeIntervalSince1970: 3)
        let item = Fixture.item(surface: .homebrew, name: "ripgrep")
        let event = Fixture.event(
            surface: .homebrew,
            kind: .added,
            itemName: "ripgrep",
            timestamp: completedAt
        )
        let finding = Fixture.finding(surface: .homebrew, itemName: "ripgrep", timestamp: completedAt)

        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [],
            current: [item],
            events: [event],
            findings: [finding],
            durationMilliseconds: 20,
            completedAt: completedAt
        ))

        #expect(try inventory.snapshot(for: .homebrew) == [item])
        #expect(try events.allEvents() == [event])
        #expect(try events.allFindings() == [finding])
        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.state == .healthy)
        #expect(surfaceHealth.lastSuccessfulScanAt == completedAt)
        #expect(surfaceHealth.lastScanTelemetry == ScanTelemetry(
            itemCount: 1,
            eventCount: 1,
            findingCount: 1,
            addedItemCount: 1
        ))
    }

    @Test
    func failedCommitScanRollsBackInventoryAndHealth() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database)
        let inventory = InventoryRepository(database: database)
        let events = EventStore(database: database)
        let health = HealthStore(database: database)
        let completedAt = Date(timeIntervalSince1970: 4)
        let previous = Fixture.item(surface: .homebrew, name: "previous")
        let current = Fixture.item(surface: .homebrew, name: "current")
        let duplicate = Fixture.event(
            surface: .homebrew,
            kind: .added,
            itemName: "current",
            timestamp: completedAt
        )

        try inventory.replace([previous], for: .homebrew)
        try health.markScanSucceeded(
            .homebrew,
            itemCount: 1,
            durationMilliseconds: 10,
            at: Date(timeIntervalSince1970: 1)
        )
        try events.append(events: [duplicate])

        #expect(throws: (any Error).self) {
            try store.commitScan(ScanCommit(
                surface: .homebrew,
                previous: [previous],
                current: [current],
                events: [duplicate],
                findings: [],
                durationMilliseconds: 20,
                completedAt: completedAt
            ))
        }

        #expect(try inventory.snapshot(for: .homebrew) == [previous])
        #expect(try events.allEvents() == [duplicate])
        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.itemCount == 1)
        #expect(surfaceHealth.lastSuccessfulScanAt == Date(timeIntervalSince1970: 1))
    }

    @Test
    func commitBaselinePersistsInventoryBaselineAndHealthAtomically() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database)
        let inventory = InventoryRepository(database: database)
        let health = HealthStore(database: database)
        let completedAt = Date(timeIntervalSince1970: 5)
        let item = Fixture.item(surface: .homebrew, name: "fd")

        try store.commitBaseline(
            surface: .homebrew,
            items: [item],
            durationMilliseconds: 30,
            completedAt: completedAt
        )

        #expect(try inventory.snapshot(for: .homebrew) == [item])
        #expect(try inventory.isBaselined(.homebrew))
        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.state == .healthy)
        #expect(surfaceHealth.lastSuccessfulScanAt == completedAt)
        #expect(surfaceHealth.lastScanTelemetry == ScanTelemetry(itemCount: 1))
    }
}
