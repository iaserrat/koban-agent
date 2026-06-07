import Foundation

struct RemoteConfigurationFetcher {
    private let client: SyncHTTPClient
    private let stateStore: EnrollmentStateStore

    init(
        client: SyncHTTPClient = SyncHTTPClient(),
        stateStore: EnrollmentStateStore = EnrollmentStateStore()
    ) {
        self.client = client
        self.stateStore = stateStore
    }

    func configurationUpdate(from configuration: KobanConfiguration) async throws -> KobanConfiguration? {
        guard configuration.sync.enabled, let state = try stateStore.load() else { return nil }
        var effective = configuration
        effective.sync.tenantID = state.tenantID
        effective.sync.deviceID = state.deviceID

        let response = try await client.getConfig(
            GetConfigRequest(
                tenantID: state.tenantID,
                deviceID: state.deviceID,
                currentGeneration: state.configGeneration ?? ""
            ),
            settings: effective.sync
        )
        guard response.configJSON.isEmpty == false else { return nil }

        // Apply before persisting the generation: a malformed payload must not advance the stored
        // generation, or the next fetch reports it as current and the server withholds the config.
        let merged = try RemoteConfigurationOverlay.apply(configJSON: response.configJSON, to: effective)
        var updatedState = state
        updatedState.configGeneration = response.generation
        try stateStore.save(updatedState)
        return merged
    }
}
