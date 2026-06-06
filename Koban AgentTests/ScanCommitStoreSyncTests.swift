import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - ScanCommitStoreSyncTests

struct ScanCommitStoreSyncTests {
    @Test
    func commitScanEnqueuesSyncEventsWhenSyncIsEnabled() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database, syncSettings: enabledSyncSettings())
        let completedAt = Date(timeIntervalSince1970: 30)
        let observedAt = Date(timeIntervalSince1970: 20)
        let item = Fixture.item(
            surface: .homebrew,
            name: "ripgrep",
            version: "14.1.1",
            installedOnRequest: true
        )
        let event = Fixture.event(
            surface: .homebrew,
            kind: .added,
            itemID: item.id,
            itemName: item.name,
            timestamp: observedAt
        )
        let finding = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            itemName: item.name,
            timestamp: observedAt
        )

        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [],
            current: [item],
            events: [event],
            findings: [finding],
            durationMilliseconds: 20,
            completedAt: completedAt
        ))

        let queued = try SyncOutboxStore(database: database).pending(limit: 10, now: completedAt)
        expectQueuedMetadata(queued, observedAt: observedAt, collectedAt: completedAt)
    }

    @Test
    func commitScanDoesNotEnqueueSyncEventsWhenSyncIsDisabled() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database)
        let completedAt = Date(timeIntervalSince1970: 30)
        let item = Fixture.item(surface: .homebrew, name: "ripgrep")
        let event = Fixture.event(
            surface: .homebrew,
            kind: .added,
            itemID: item.id,
            itemName: item.name,
            timestamp: completedAt
        )

        try store.commitScan(ScanCommit(
            surface: .homebrew,
            previous: [],
            current: [item],
            events: [event],
            findings: [],
            durationMilliseconds: 20,
            completedAt: completedAt
        ))

        let queued = try SyncOutboxStore(database: database).pending(limit: 10, now: completedAt)
        #expect(queued.isEmpty)
    }

    @Test
    func commitBaselineEnqueuesAddedSyncEventsWhenSyncIsEnabled() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database, syncSettings: enabledSyncSettings())
        let completedAt = Date(timeIntervalSince1970: 30)
        let first = Fixture.item(surface: .homebrew, name: "ripgrep", version: "14.1.1")
        let second = Fixture.item(surface: .homebrew, name: "fd", version: "10.0.0")

        try store.commitBaseline(
            surface: .homebrew,
            items: [first, second],
            durationMilliseconds: 20,
            completedAt: completedAt
        )

        let queued = try SyncOutboxStore(database: database).pending(limit: 10, now: completedAt)
        #expect(queued.count == 2)
        #expect(queued.map(\.localSequence) == [1, 2])
        #expect(queued.allSatisfy { $0.surface == .homebrew })
        #expect(queued.allSatisfy { $0.kind == .added })
        #expect(queued.allSatisfy { $0.observedAt == completedAt })
        #expect(queued.allSatisfy { $0.collectedAt == completedAt })
        #expect(queued.allSatisfy { $0.payloadHash == PayloadHasher.sha256Hex($0.payload) })
    }

    @Test
    func commitBaselineDoesNotEnqueueSyncEventsWhenSyncIsDisabled() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = ScanCommitStore(database: database)
        let completedAt = Date(timeIntervalSince1970: 30)
        let item = Fixture.item(surface: .homebrew, name: "ripgrep")

        try store.commitBaseline(
            surface: .homebrew,
            items: [item],
            durationMilliseconds: 20,
            completedAt: completedAt
        )

        let queued = try SyncOutboxStore(database: database).pending(limit: 10, now: completedAt)
        #expect(queued.isEmpty)
    }

    private func enabledSyncSettings() -> SyncSettings {
        var settings = DefaultConfiguration.value.sync
        settings.enabled = true
        settings.tenantID = ScanCommitStoreSyncTestConstants.tenantID
        settings.deviceID = ScanCommitStoreSyncTestConstants.deviceID
        return settings
    }

    private func expectQueuedMetadata(
        _ queued: [SyncOutboxEvent],
        observedAt: Date,
        collectedAt: Date
    ) {
        #expect(queued.count == 2)
        #expect(queued.map(\.localSequence) == [1, 2])
        #expect(queued.map(\.tenantID) == [
            ScanCommitStoreSyncTestConstants.tenantID,
            ScanCommitStoreSyncTestConstants.tenantID
        ])
        #expect(queued.map(\.deviceID) == [
            ScanCommitStoreSyncTestConstants.deviceID,
            ScanCommitStoreSyncTestConstants.deviceID
        ])
        #expect(queued.map(\.schemaVersion) == [
            SensorProtocolConstants.schemaVersion,
            SensorProtocolConstants.schemaVersion
        ])
        #expect(queued[0].surface == .homebrew)
        #expect(queued[0].kind == .added)
        #expect(queued[0].observedAt == observedAt)
        #expect(queued[0].collectedAt == collectedAt)
        #expect(queued[0].payloadHash == PayloadHasher.sha256Hex(queued[0].payload))
        #expect(queued[1].surface == .homebrew)
        #expect(queued[1].kind == SensorProtocolConstants.findingEventKind)
        #expect(queued[1].observedAt == observedAt)
        #expect(queued[1].collectedAt == collectedAt)
        #expect(queued[1].payloadHash == PayloadHasher.sha256Hex(queued[1].payload))
    }
}

// MARK: - ScanCommitStoreSyncTestConstants

private enum ScanCommitStoreSyncTestConstants {
    static let tenantID = "tenant-a"
    static let deviceID = "device-a"
}
