import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - SyncUploaderTests

struct SyncUploaderTests {
    @Test
    func uploadOnceAppliesAcceptedAndRejectedDecisions() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = SyncOutboxStore(database: database)
        let now = Date(timeIntervalSince1970: 100)
        try store.enqueue(event(sequence: 1, now: now))
        try store.enqueue(event(sequence: 2, now: now))
        try store.enqueue(event(sequence: 3, now: now))

        let response = SyncResponse(
            acceptedThroughLocalSequence: 1,
            acceptedEvents: [AcceptedSyncEvent(eventID: "event-2", localSequence: 2, duplicate: false)],
            rejectedEvents: [
                RejectedSyncEvent(
                    eventID: "event-3",
                    localSequence: 3,
                    code: "invalid_payload",
                    message: "bad"
                )
            ],
            serverTime: "2026-06-01T10:00:00Z",
            configGeneration: "generation-a",
            configUpdateAvailable: false,
            fullResnapshotRequested: false,
            retryAfterSeconds: 0,
            maxBatchBytes: 0,
            maxBatchEvents: 0
        )
        let uploader = try SyncUploader(
            store: store,
            client: SyncHTTPClient(transport: StubTransport(data: JSONEncoder().encode(response)))
        )

        let result = try await uploader.uploadOnce(settings: syncSettings(), now: now)

        #expect(result == uploadResult(uploaded: 3, accepted: 2, rejected: 1))
        #expect(try store.pending(limit: 10, now: now).isEmpty)
        #expect(try store.lastAckedLocalSequence(deviceID: "device-a") == 2)
        #expect(try store.backlog(deviceID: "device-a") == SyncBacklog(eventCount: 0, byteCount: 0))
    }

    private func uploadResult(
        uploaded: Int = 0,
        accepted: Int = 0,
        rejected: Int = 0,
        retries: Int = 0,
        configUpdateAvailable: Bool = false,
        fullResnapshotRequested: Bool = false
    ) -> SyncUploadResult {
        SyncUploadResult(
            uploadedEventCount: uploaded,
            acceptedEventCount: accepted,
            rejectedEventCount: rejected,
            retryEventCount: retries,
            configUpdateAvailable: configUpdateAvailable,
            fullResnapshotRequested: fullResnapshotRequested
        )
    }

    @Test
    func uploadFailureSchedulesBatchForRetry() async throws {
        let database = try AppDatabase(DatabaseQueue())
        let store = SyncOutboxStore(database: database)
        let now = Date(timeIntervalSince1970: 100)
        try store.enqueue(event(sequence: 1, now: now))

        let uploader = SyncUploader(
            store: store,
            client: SyncHTTPClient(transport: FailingTransport(error: SyncUploadError.serverStatus(500)))
        )

        await #expect(throws: SyncUploadError.serverStatus(500)) {
            try await uploader.uploadOnce(settings: syncSettings(), now: now)
        }

        #expect(try store.pending(limit: 10, now: now).isEmpty)
        let retryAt = now.addingTimeInterval(TimeInterval(ConfigurationDefaults.syncRetryBaseSeconds))
        let pending = try store.pending(limit: 10, now: retryAt)
        #expect(pending.map(\.localSequence) == [1])
        #expect(pending.first?.attemptCount == 1)
    }

    private func syncSettings() -> SyncSettings {
        var settings = DefaultConfiguration.value.sync
        settings.enabled = true
        settings.endpoint = "https://fleet.example.com"
        settings.enrollmentToken = "token-a"
        settings.sensorToken = "token-a"
        settings.tenantID = "tenant-a"
        settings.deviceID = "device-a"
        settings.maxBatchEvents = 10
        settings.maxBatchBytes = 1000
        return settings
    }

    private func event(sequence: Int64, now: Date) -> SyncOutboxEvent {
        let payload = Data("payload-\(sequence)".utf8)
        return SyncOutboxEvent(
            id: UUID(),
            tenantID: "tenant-a",
            deviceID: "device-a",
            localSequence: sequence,
            schemaVersion: 1,
            surface: .homebrew,
            kind: .added,
            observedAt: now,
            collectedAt: now,
            payload: payload,
            payloadHash: "hash-\(sequence)",
            state: .pending,
            attemptCount: 0,
            nextAttemptAt: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}

// MARK: - StubTransport

private struct StubTransport: SyncHTTPTransport {
    private static let statusOK = 200

    var data: Data

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: Self.statusOK,
            httpVersion: nil,
            headerFields: nil
        ) ?? URLResponse()
        return (data, response)
    }
}

// MARK: - FailingTransport

private struct FailingTransport: SyncHTTPTransport {
    var error: SyncUploadError

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw error
    }
}
