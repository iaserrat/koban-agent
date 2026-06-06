import Foundation
import GRDB
import Testing
@testable import Koban_Agent

struct PresentScanCommitStoreSyncTests {
    @Test
    func commitScanEnqueuesDedupedPresentFindingWhenSyncIsEnabled() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database, syncSettings: enabledSyncSettings())
        let completedAt = Date(timeIntervalSince1970: 30)
        let item = Fixture.item(surface: .homebrew, name: "copilot-for-xcode")
        let finding = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "homebrew.ioc",
            itemName: item.name,
            timestamp: completedAt,
            severity: .critical
        )

        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [item],
            current: [item],
            events: [],
            findings: [],
            presentFindings: [finding],
            durationMilliseconds: 20,
            completedAt: completedAt
        ))
        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [item],
            current: [item],
            events: [],
            findings: [],
            presentFindings: [finding],
            durationMilliseconds: 20,
            completedAt: Date(timeIntervalSince1970: 31)
        ))

        let queued = try SyncOutboxStore(database: database).pending(limit: 10, now: completedAt)
        #expect(queued.count == 1)
        #expect(queued[0].surface == .homebrew)
        #expect(queued[0].kind == SensorProtocolConstants.findingEventKind)
        #expect(queued[0].observedAt == completedAt)
        #expect(queued[0].collectedAt == completedAt)
    }

    @Test
    func commitBaselineEnqueuesDedupedPresentFindingWhenSyncIsEnabled() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database, syncSettings: enabledSyncSettings())
        let firstCompletedAt = Date(timeIntervalSince1970: 40)
        let secondCompletedAt = Date(timeIntervalSince1970: 41)
        let item = Fixture.item(surface: .homebrew, name: "copilot-for-xcode")
        let first = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "homebrew.ioc",
            itemName: item.name,
            timestamp: firstCompletedAt,
            severity: .critical
        )
        let second = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "homebrew.ioc",
            itemName: item.name,
            timestamp: secondCompletedAt,
            severity: .critical
        )

        try store.commitBaseline(
            surface: .homebrew,
            items: [item],
            findings: [first],
            durationMilliseconds: 20,
            completedAt: firstCompletedAt
        )
        try store.commitBaseline(
            surface: .homebrew,
            items: [item],
            findings: [second],
            durationMilliseconds: 20,
            completedAt: secondCompletedAt
        )

        let queued = try SyncOutboxStore(database: database).pending(limit: 10, now: secondCompletedAt)
        let findingEvents = queued.filter { $0.kind == SensorProtocolConstants.findingEventKind }
        #expect(findingEvents.count == 1)
        #expect(findingEvents[0].observedAt == firstCompletedAt)
        #expect(findingEvents[0].collectedAt == firstCompletedAt)
    }

    private func enabledSyncSettings() -> SyncSettings {
        var settings = DefaultConfiguration.value.sync
        settings.enabled = true
        settings.tenantID = "tenant-a"
        settings.deviceID = "device-a"
        return settings
    }
}
