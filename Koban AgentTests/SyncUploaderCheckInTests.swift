import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - SyncUploaderCheckInTests

struct SyncUploaderCheckInTests {
    @Test
    func uploadOnceChecksInWhenNoEventsArePending() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let database = try AppDatabase(DatabaseQueue())
            let store = SyncOutboxStore(database: database)
            let now = Date(timeIntervalSince1970: 100)
            let stateStore = EnrollmentStateStore(
                fileURL: directory.appending(component: "sync-state.json")
            )
            try stateStore.save(enrollmentState())
            let transport = try RecordingCheckInTransport(data: JSONEncoder().encode(checkInResponse()))
            let uploader = checkInUploader(store: store, transport: transport, stateStore: stateStore)

            let result = try await uploader.uploadOnce(settings: syncSettings(), now: now)

            #expect(result == uploadResult(configUpdateAvailable: true, fullResnapshotRequested: true))
            try await assertCheckInRequest(transport)
        }
    }

    private func assertCheckInRequest(_ transport: RecordingCheckInTransport) async throws {
        let request = try await transport.recordedRequest()
        #expect(request.url?.path == "/api/sensor/v1/check-in")
        let body = try #require(request.httpBody)
        let checkIn = try JSONDecoder().decode(CheckInRequest.self, from: body)
        #expect(checkIn.activeConfigGeneration == "generation-a")
        #expect(checkIn.health == SensorHealthRequest(syncBacklogEvents: 0, syncBacklogBytes: 0))
    }

    private func uploadResult(
        configUpdateAvailable: Bool,
        fullResnapshotRequested: Bool
    ) -> SyncUploadResult {
        SyncUploadResult(
            uploadedEventCount: 0,
            acceptedEventCount: 0,
            rejectedEventCount: 0,
            retryEventCount: 0,
            configUpdateAvailable: configUpdateAvailable,
            fullResnapshotRequested: fullResnapshotRequested
        )
    }

    private func enrollmentState() -> EnrollmentState {
        EnrollmentState(
            tenantID: "tenant-a",
            deviceID: "device-a",
            clientCertificate: Data("certificate".utf8),
            certificateExpiresAt: "2026-08-01T00:00:00Z",
            configGeneration: "generation-a"
        )
    }

    private func checkInResponse() -> CheckInResponse {
        CheckInResponse(
            serverTime: "2026-06-01T10:00:00Z",
            configGeneration: "generation-b",
            configUpdateAvailable: true,
            certificateRenewalRequired: false,
            fullResnapshotRequested: true
        )
    }

    private func checkInUploader(
        store: SyncOutboxStore,
        transport: RecordingCheckInTransport,
        stateStore: EnrollmentStateStore
    ) -> SyncUploader {
        SyncUploader(
            store: store,
            client: SyncHTTPClient(transport: transport),
            stateStore: stateStore,
            host: HostIdentityProvider(
                hostname: { "mac-a" },
                osVersion: { "15.5" },
                hardwareModel: { "Mac15,3" }
            )
        )
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
}

// MARK: - RecordingCheckInTransport

private actor RecordingCheckInTransport: SyncHTTPTransport {
    private static let statusOK = 200

    private let data: Data
    private var request: URLRequest?

    init(data: Data) {
        self.data = data
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        self.request = request
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: Self.statusOK,
            httpVersion: nil,
            headerFields: nil
        ) ?? URLResponse()
        return (data, response)
    }

    func recordedRequest() throws -> URLRequest {
        try #require(request)
    }
}
