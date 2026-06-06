import Foundation
import Testing
@testable import Koban_Agent

// MARK: - RemoteConfigurationFetcherTests

struct RemoteConfigurationFetcherTests {
    fileprivate static let statusOK = 200
    private static let generation = "generation-b"
    private static let tenantID = "tenant-a"
    private static let deviceID = "device-a"
    private static let debounceMilliseconds = 321

    @Test
    func fetchesRemoteConfigWithoutSensorTokenForMTLSAuthentication() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let stateURL = directory.appending(component: SensorProtocolConstants.enrollmentStateFileName)
            try EnrollmentStateStore(fileURL: stateURL).save(enrollmentState())
            let transport = try QueueTransport(responses: [
                JSONEncoder().encode(configResponse())
            ])
            let fetcher = RemoteConfigurationFetcher(
                client: SyncHTTPClient(transport: transport),
                stateStore: EnrollmentStateStore(fileURL: stateURL)
            )

            let updated = try #require(try await fetcher.configurationUpdate(from: localConfiguration()))

            #expect(updated.sync.tenantID == Self.tenantID)
            #expect(updated.sync.deviceID == Self.deviceID)
            #expect(updated.sync.sensorToken == nil)
            #expect(updated.watch.debounceMilliseconds == Self.debounceMilliseconds)

            let state = try #require(try EnrollmentStateStore(fileURL: stateURL).load())
            #expect(state.configGeneration == Self.generation)

            let request = try await transport.configRequest()
            #expect(request.tenantID == Self.tenantID)
            #expect(request.deviceID == Self.deviceID)
            #expect(request.currentGeneration.isEmpty)
            let tokenHeaders = await transport.sensorTokenHeaders
            #expect(tokenHeaders.count == 1)
            #expect(tokenHeaders[0] == nil)
        }
    }

    @Test
    func treatsNullConfigBytesAsEmptyConfigResponse() throws {
        let data = Data(
            """
            {
              "generation": "\(Self.generation)",
              "configJson": null,
              "signature": null
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(GetConfigResponse.self, from: data)

        #expect(response.generation == Self.generation)
        #expect(response.configJSON.isEmpty)
        #expect(response.signature.isEmpty)
    }

    private func localConfiguration() -> KobanConfiguration {
        var configuration = DefaultConfiguration.value
        configuration.sync.enabled = true
        configuration.sync.endpoint = "https://fleet.example.com"
        configuration.sync.sensorToken = nil
        return configuration
    }

    private func enrollmentState() -> EnrollmentState {
        EnrollmentState(
            tenantID: Self.tenantID,
            deviceID: Self.deviceID,
            clientCertificate: Data("certificate".utf8),
            certificateExpiresAt: "2026-06-01T10:00:00Z",
            configGeneration: nil
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
            "debounceMilliseconds": \(Self.debounceMilliseconds)
          },
          "rules": []
        }
        """
    }
}

// MARK: - QueueTransport

private actor QueueTransport: SyncHTTPTransport {
    private var responses: [Data]
    private var requests: [Data] = []
    private(set) var sensorTokenHeaders: [String?] = []

    init(responses: [Data]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request.httpBody ?? Data())
        sensorTokenHeaders
            .append(request.value(forHTTPHeaderField: SensorProtocolConstants.sensorTokenHeader))
        let data = responses.removeFirst()
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: RemoteConfigurationFetcherTests.statusOK,
            httpVersion: nil,
            headerFields: nil
        ) ?? URLResponse()
        return (data, response)
    }

    func configRequest() throws -> GetConfigRequest {
        try JSONDecoder().decode(GetConfigRequest.self, from: requests[0])
    }
}
