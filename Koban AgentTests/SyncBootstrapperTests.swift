import Foundation
import Security
import Testing
@testable import Koban_Agent

// MARK: - SyncBootstrapperTests

struct SyncBootstrapperTests {
    fileprivate static let statusOK = 200
    private static let remoteDebounceMilliseconds = 123
    private static let remotePollIntervalSeconds = 456
    private static let remoteMaxBatchBytes = 789
    private static let remoteMaxBatchEvents = 12
    private static let generation = "generation-a"

    @Test
    func enrollsPersistsIdentityAndAppliesRemoteConfig() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let stateURL = directory.appending(component: SensorProtocolConstants.enrollmentStateFileName)
            let transport = try QueueTransport(responses: [
                JSONEncoder().encode(enrollmentResponse()),
                JSONEncoder().encode(configResponse())
            ])
            let bootstrapper = SyncBootstrapper(
                client: SyncHTTPClient(transport: transport),
                stateStore: EnrollmentStateStore(fileURL: stateURL),
                identityStore: FakeEnrollmentIdentityStore(),
                host: HostIdentityProvider(
                    hostname: { "macbook" },
                    osVersion: { "15.5" },
                    hardwareModel: { "MacBookPro" }
                )
            )

            let bootstrapped = await bootstrapper.bootstrap(localConfiguration())

            #expect(bootstrapped.sync.tenantID == "tenant-a")
            #expect(bootstrapped.sync.deviceID == "device-a")
            #expect(bootstrapped.sync.endpoint == "https://fleet.example.com")
            #expect(bootstrapped.sync.sensorToken == "sensor-token")
            #expect(bootstrapped.watch.debounceMilliseconds == Self.remoteDebounceMilliseconds)
            #expect(bootstrapped.watch.pollIntervalSeconds == Self.remotePollIntervalSeconds)
            #expect(bootstrapped.sync.maxBatchBytes == Self.remoteMaxBatchBytes)
            #expect(bootstrapped.sync.maxBatchEvents == Self.remoteMaxBatchEvents)

            let state = try #require(try EnrollmentStateStore(fileURL: stateURL).load())
            #expect(state.tenantID == "tenant-a")
            #expect(state.deviceID == "device-a")
            #expect(state.configGeneration == Self.generation)

            let paths = await transport.paths
            #expect(paths == [
                "/api/sensor/v1/enroll",
                "/api/sensor/v1/config"
            ])
            let request = try await transport.enrollmentRequest()
            #expect(request.publicKey == FakeEnrollmentIdentityStore.publicKey)
        }
    }

    private func localConfiguration() -> KobanConfiguration {
        var configuration = DefaultConfiguration.value
        configuration.sync.enabled = true
        configuration.sync.endpoint = "https://fleet.example.com"
        configuration.sync.enrollmentToken = "enrollment-token"
        configuration.sync.sensorToken = "sensor-token"
        return configuration
    }

    private func enrollmentResponse() -> EnrollmentResponse {
        EnrollmentResponse(
            tenantID: "tenant-a",
            deviceID: "device-a",
            clientCertificate: Data("certificate".utf8),
            certificateExpiresAt: "2026-06-01T10:00:00Z"
        )
    }

    private func configResponse() -> GetConfigResponse {
        GetConfigResponse(
            generation: Self.generation,
            configJSON: Data(remoteConfigJSON().utf8),
            signature: Data()
        )
    }

    private func remoteConfigJSON() -> String {
        """
        {
          "watch": {
            "debounceMilliseconds": \(Self.remoteDebounceMilliseconds),
            "pollIntervalSeconds": \(Self.remotePollIntervalSeconds)
          },
          "sync": {
            "maxBatchBytes": \(Self.remoteMaxBatchBytes),
            "maxBatchEvents": \(Self.remoteMaxBatchEvents)
          },
          "rules": []
        }
        """
    }
}

// MARK: - QueueTransport

private actor QueueTransport: SyncHTTPTransport {
    private var responses: [Data]
    private(set) var paths: [String] = []
    private var requests: [Data] = []

    init(responses: [Data]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        paths.append(request.url?.path ?? "")
        requests.append(request.httpBody ?? Data())
        let data = responses.removeFirst()
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: SyncBootstrapperTests.statusOK,
            httpVersion: nil,
            headerFields: nil
        ) ?? URLResponse()
        return (data, response)
    }

    func enrollmentRequest() throws -> EnrollmentRequest {
        try JSONDecoder().decode(EnrollmentRequest.self, from: requests[0])
    }
}

// MARK: - FakeEnrollmentIdentityStore

private struct FakeEnrollmentIdentityStore: EnrollmentIdentityStore {
    static let publicKey = Data("public-key".utf8)

    func publicKeyPEM() throws -> Data {
        Self.publicKey
    }

    func identity(certificateData _: Data) -> SecIdentity? {
        nil
    }
}
