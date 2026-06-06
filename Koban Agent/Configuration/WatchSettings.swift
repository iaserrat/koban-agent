import Foundation

// MARK: - WatchSettings

/// Timing and discovery settings for the watch pipeline.
struct WatchSettings: Decodable, Hashable {
    var debounceMilliseconds: Int
    var pollIntervalSeconds: Int
    var maxScanWallClockSeconds: Int
    var maxFreshScanAgeSeconds: Int
    var projectDiscovery: ProjectDiscoverySettings
    var homeSignalScan: HomeSignalScanSettings

    init(
        debounceMilliseconds: Int,
        pollIntervalSeconds: Int,
        maxScanWallClockSeconds: Int,
        maxFreshScanAgeSeconds: Int,
        projectDiscovery: ProjectDiscoverySettings,
        homeSignalScan: HomeSignalScanSettings
    ) {
        self.debounceMilliseconds = debounceMilliseconds
        self.pollIntervalSeconds = pollIntervalSeconds
        self.maxScanWallClockSeconds = maxScanWallClockSeconds
        self.maxFreshScanAgeSeconds = maxFreshScanAgeSeconds
        self.projectDiscovery = projectDiscovery
        self.homeSignalScan = homeSignalScan
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.watch
        debounceMilliseconds = try container.decodeIfPresent(
            Int.self,
            forKey: .debounceMilliseconds
        ) ?? defaults.debounceMilliseconds
        pollIntervalSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .pollIntervalSeconds
        ) ?? defaults.pollIntervalSeconds
        maxScanWallClockSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .maxScanWallClockSeconds
        ) ?? defaults.maxScanWallClockSeconds
        maxFreshScanAgeSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .maxFreshScanAgeSeconds
        ) ?? defaults.maxFreshScanAgeSeconds
        projectDiscovery = try ProjectDiscoverySettings(from: decoder, defaults: defaults.projectDiscovery)
        homeSignalScan = try container.decodeIfPresent(
            HomeSignalScanSettings.self,
            forKey: .homeSignalScan
        ) ?? defaults.homeSignalScan
    }

    private enum CodingKeys: String, CodingKey {
        case debounceMilliseconds
        case pollIntervalSeconds
        case maxScanWallClockSeconds
        case maxFreshScanAgeSeconds
        case homeSignalScan
    }
}

// MARK: Encodable

extension WatchSettings: Encodable {
    /// Mirrors `init(from:)`: the four scalars and `homeSignalScan` go under `watch`, and
    /// `projectDiscovery`'s keys are flattened into the same container (it is decoded from the
    /// shared `watch` decoder, not a nested key), so the round-trip stays byte-shape stable.
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(debounceMilliseconds, forKey: .debounceMilliseconds)
        try container.encode(pollIntervalSeconds, forKey: .pollIntervalSeconds)
        try container.encode(maxScanWallClockSeconds, forKey: .maxScanWallClockSeconds)
        try container.encode(maxFreshScanAgeSeconds, forKey: .maxFreshScanAgeSeconds)
        try container.encode(homeSignalScan, forKey: .homeSignalScan)
        try projectDiscovery.encode(to: encoder)
    }
}
