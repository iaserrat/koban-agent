import Foundation
import GRDB
import Testing
@testable import Koban_Agent

struct PresentScanCommitStoreTests {
    @Test
    func commitScanDedupesPresentFindingsBySurfaceItemAndRule() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database)
        let events = EventStore(database: database)
        let completedAt = Date(timeIntervalSince1970: 6)
        let item = Fixture.item(surface: .homebrew, name: "copilot-for-xcode")
        let first = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "homebrew.ioc",
            itemName: item.name,
            timestamp: completedAt
        )
        let second = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "homebrew.ioc",
            itemName: item.name,
            timestamp: Date(timeIntervalSince1970: 7)
        )

        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [],
            current: [item],
            events: [],
            findings: [],
            presentFindings: [first],
            durationMilliseconds: 20,
            completedAt: completedAt
        ))
        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [item],
            current: [item],
            events: [],
            findings: [],
            presentFindings: [second],
            durationMilliseconds: 20,
            completedAt: Date(timeIntervalSince1970: 7)
        ))

        #expect(try events.allFindings() == [first])
    }

    @Test
    func commitBaselinePersistsPresentFindings() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database)
        let events = EventStore(database: database)
        let health = HealthStore(database: database)
        let completedAt = Date(timeIntervalSince1970: 8)
        let item = Fixture.item(surface: .homebrew, name: "copilot-for-xcode")
        let finding = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "homebrew.ioc",
            itemName: item.name,
            timestamp: completedAt
        )

        try store.commitBaseline(
            surface: .homebrew,
            items: [item],
            findings: [finding],
            durationMilliseconds: 20,
            completedAt: completedAt
        )

        #expect(try events.allFindings() == [finding])
        let surfaceHealth = try #require(health.allHealth().first)
        #expect(surfaceHealth.lastScanTelemetry == ScanTelemetry(itemCount: 1, findingCount: 1))
    }

    @Test
    func repeatedBaselineDoesNotDuplicatePresentFinding() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database)
        let events = EventStore(database: database)
        let item = Fixture.item(surface: .homebrew, name: "copilot-for-xcode")
        let first = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "homebrew.ioc",
            itemName: item.name,
            timestamp: Date(timeIntervalSince1970: 9)
        )
        let second = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "homebrew.ioc",
            itemName: item.name,
            timestamp: Date(timeIntervalSince1970: 10)
        )

        try store.commitBaseline(
            surface: .homebrew,
            items: [item],
            findings: [first],
            durationMilliseconds: 20,
            completedAt: Date(timeIntervalSince1970: 9)
        )
        try store.commitBaseline(
            surface: .homebrew,
            items: [item],
            findings: [second],
            durationMilliseconds: 20,
            completedAt: Date(timeIntervalSince1970: 10)
        )

        #expect(try events.allFindings() == [first])
    }
}
