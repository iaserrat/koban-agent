import Foundation

enum RemoteConfigurationOverlay {
    static func apply(configJSON: Data, to local: KobanConfiguration) throws -> KobanConfiguration {
        let remote = try JSONDecoder().decode(KobanConfiguration.self, from: configJSON)
        var merged = local
        merged.watch = remote.watch
        merged.rules = remote.rules
        merged.sync.maxBatchBytes = remote.sync.maxBatchBytes
        merged.sync.maxBatchEvents = remote.sync.maxBatchEvents
        return merged
    }
}
