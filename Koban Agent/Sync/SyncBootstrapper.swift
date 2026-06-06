import Foundation
import OSLog

struct SyncBootstrapper {
    private let client: SyncHTTPClient
    private let stateStore: EnrollmentStateStore
    private let identityStore: any EnrollmentIdentityStore
    private let remoteConfig: RemoteConfigurationFetcher
    private let host: HostIdentityProvider

    init(
        client: SyncHTTPClient = SyncHTTPClient(),
        stateStore: EnrollmentStateStore = EnrollmentStateStore(),
        identityStore: any EnrollmentIdentityStore = KeychainEnrollmentIdentityStore(),
        host: HostIdentityProvider = .live
    ) {
        self.client = client
        self.stateStore = stateStore
        self.identityStore = identityStore
        remoteConfig = RemoteConfigurationFetcher(client: client, stateStore: stateStore)
        self.host = host
    }

    func bootstrap(_ configuration: KobanConfiguration) async -> KobanConfiguration {
        guard configuration.sync.enabled else { return configuration }

        do {
            var state = try stateStore.load()
            var effective = configuration
            if state == nil, let enrolled = try await enrollIfPossible(settings: configuration.sync) {
                state = enrolled
                try stateStore.save(enrolled)
            }
            if state != nil {
                effective = try await remoteConfig.configurationUpdate(from: effective) ?? effective
            }
            return effective
        } catch {
            Log.sync.error("Sensor bootstrap failed: \(error).")
            return configuration
        }
    }

    private func enrollIfPossible(settings: SyncSettings) async throws -> EnrollmentState? {
        guard let token = settings.enrollmentToken, settings.endpoint != nil else {
            return nil
        }
        let response = try await client.enroll(
            EnrollmentRequest(
                token: token,
                publicKey: identityStore.publicKeyPEM(),
                hostname: host.hostname(),
                osVersion: host.osVersion(),
                hardwareModel: host.hardwareModel(),
                sensorVersion: SensorProtocolConstants.sensorVersion
            ),
            settings: settings
        )
        return EnrollmentState(
            tenantID: response.tenantID,
            deviceID: response.deviceID,
            clientCertificate: response.clientCertificate,
            certificateExpiresAt: response.certificateExpiresAt,
            configGeneration: nil
        )
    }
}
