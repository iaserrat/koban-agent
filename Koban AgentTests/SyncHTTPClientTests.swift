import Foundation
import Testing
@testable import Koban_Agent

struct SyncHTTPClientTests {
    @Test
    func buildsBackendJSONSyncRequest() throws {
        let client = SyncHTTPClient()
        let request = syncRequest()

        let urlRequest = try client.buildURLRequest(request, settings: syncSettings())

        #expect(urlRequest.url?.absoluteString == "https://fleet.example.com/api/sensor/v1/sync")
        #expect(urlRequest.httpMethod == SensorProtocolConstants.httpMethodPOST)
        #expect(
            urlRequest.value(
                forHTTPHeaderField: SensorProtocolConstants.contentTypeHeader
            ) == SensorProtocolConstants.applicationJSONContentType
        )
        #expect(urlRequest.value(forHTTPHeaderField: SensorProtocolConstants.sensorTokenHeader) == "token-a")

        let body = try #require(urlRequest.httpBody)
        let decoded = try JSONDecoder().decode(SyncRequest.self, from: body)
        #expect(decoded.tenantID == "tenant-a")
        #expect(decoded.deviceID == "device-a")
        #expect(decoded.events.first?.payload == Data("payload-a".utf8))
    }

    @Test
    func buildsSensorRequestWithoutTokenForMTLSAuthentication() throws {
        let client = SyncHTTPClient()
        var settings = syncSettings()
        settings.sensorToken = nil

        let urlRequest = try client.buildURLRequest(syncRequest(), settings: settings)

        #expect(urlRequest.url?.absoluteString == "https://fleet.example.com/api/sensor/v1/sync")
        #expect(urlRequest.value(forHTTPHeaderField: SensorProtocolConstants.sensorTokenHeader) == nil)
    }

    private func syncRequest() -> SyncRequest {
        SyncRequest(
            tenantID: "tenant-a",
            deviceID: "device-a",
            sensorVersion: "sensor-a",
            schemaVersion: 1,
            lastAckedLocalSequence: 4,
            events: [
                SyncEventRequest(
                    eventID: "event-a",
                    deviceID: "device-a",
                    localSequence: 5,
                    surface: .homebrew,
                    kind: .added,
                    observedAt: "2026-06-01T10:00:00.000Z",
                    collectedAt: "2026-06-01T10:00:01.000Z",
                    payloadHash: "hash-a",
                    payload: Data("payload-a".utf8)
                )
            ],
            health: SensorHealthRequest(syncBacklogEvents: 1, syncBacklogBytes: 9)
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
        return settings
    }
}
