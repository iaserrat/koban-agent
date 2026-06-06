import Foundation
import GRDB
import Testing
@testable import Koban_Agent

struct SyncOutboxStoreTests {
    @Test
    func pendingReturnsReadyEventsInSequenceOrder() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = SyncOutboxStore(database: database)
        let now = Date(timeIntervalSince1970: 100)
        try store.enqueue(event(sequence: 2, nextAttemptAt: now.addingTimeInterval(1), now: now))
        try store.enqueue(event(sequence: 1, now: now))
        try store.enqueue(event(sequence: 3, state: .acked, now: now))

        let pending = try store.pending(limit: 10, now: now)

        #expect(pending.map(\.localSequence) == [1])
    }

    @Test
    func markAckedUpdatesOnlySelectedSequences() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = SyncOutboxStore(database: database)
        let now = Date(timeIntervalSince1970: 100)
        try store.enqueue(event(sequence: 1, now: now))
        try store.enqueue(event(sequence: 2, now: now))

        try store.markAcked(localSequences: [2], at: now.addingTimeInterval(1))

        let pending = try store.pending(limit: 10, now: now.addingTimeInterval(2))
        #expect(pending.map(\.localSequence) == [1])
    }

    @Test
    func backlogCountsPendingAndInFlightBytes() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = SyncOutboxStore(database: database)
        let now = Date(timeIntervalSince1970: 100)
        try store.enqueue(event(sequence: 1, state: .pending, now: now))
        try store.enqueue(event(sequence: 2, state: .inFlight, now: now))
        try store.enqueue(event(sequence: 3, state: .acked, now: now))

        let backlog = try store.backlog(deviceID: "device-a")

        #expect(backlog.eventCount == 2)
        #expect(backlog.byteCount == UInt64(Data("payload-1".utf8).count + Data("payload-2".utf8).count))
    }

    @Test
    func lastAckedLocalSequenceIsScopedByDevice() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = SyncOutboxStore(database: database)
        let now = Date(timeIntervalSince1970: 100)
        try store.enqueue(event(deviceID: "device-a", sequence: 4, state: .acked, now: now))
        try store.enqueue(event(deviceID: "device-b", sequence: 7, state: .acked, now: now))
        try store.enqueue(event(deviceID: "device-a", sequence: 5, state: .pending, now: now))

        #expect(try store.lastAckedLocalSequence(deviceID: "device-a") == 4)
        #expect(try store.lastAckedLocalSequence(deviceID: "device-b") == 7)
    }

    @Test
    func retryMovesInFlightBackToPendingWithNextAttempt() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = SyncOutboxStore(database: database)
        let now = Date(timeIntervalSince1970: 100)
        let retryAt = Date(timeIntervalSince1970: 200)
        try store.enqueue(event(sequence: 1, state: .inFlight, now: now))

        try store.scheduleRetry(localSequences: [1], nextAttemptAt: retryAt, at: now)

        let pending = try store.pending(limit: 10, now: retryAt)
        #expect(pending.map(\.localSequence) == [1])
        #expect(pending.first?.attemptCount == 1)
        #expect(pending.first?.nextAttemptAt == retryAt)
    }

    @Test
    func poisonEventsAreNotPending() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = SyncOutboxStore(database: database)
        let now = Date(timeIntervalSince1970: 100)
        try store.enqueue(event(sequence: 1, now: now))

        try store.markPoison(localSequences: [1], at: now)

        let pending = try store.pending(limit: 10, now: now)
        #expect(pending.isEmpty)
    }

    @Test
    func nextLocalSequenceIsScopedByDevice() throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = SyncOutboxStore(database: database)
        let now = Date(timeIntervalSince1970: 100)
        try store.enqueue(event(deviceID: "device-a", sequence: 3, now: now))
        try store.enqueue(event(deviceID: "device-b", sequence: 1, now: now))

        #expect(try store.nextLocalSequence(deviceID: "device-a") == 4)
        #expect(try store.nextLocalSequence(deviceID: "device-b") == 2)
    }

    private func event(
        deviceID: String = "device-a",
        sequence: Int64,
        state: SyncEventState = .pending,
        nextAttemptAt: Date? = nil,
        now: Date
    ) -> SyncOutboxEvent {
        let payload = Data("payload-\(sequence)".utf8)
        return SyncOutboxEvent(
            id: UUID(),
            tenantID: "tenant-a",
            deviceID: deviceID,
            localSequence: sequence,
            schemaVersion: 1,
            surface: .homebrew,
            kind: .added,
            observedAt: now,
            collectedAt: now,
            payload: payload,
            payloadHash: "hash-\(sequence)",
            state: state,
            attemptCount: 0,
            nextAttemptAt: nextAttemptAt,
            createdAt: now,
            updatedAt: now
        )
    }
}
