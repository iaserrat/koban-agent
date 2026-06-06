import Foundation

/// Typed defaults for YAML configuration values.
enum ConfigurationDefaults {
    static let debounceMilliseconds = 800
    static let pollIntervalSeconds = 300
    static let maxScanWallClockSeconds = 30
    static let maxFreshScanAgeSeconds = 900
    static let maxStoredEvents = 5000
    static let maxStoredFindings = 1000
    static let syncEnabled = false
    static let syncProtocolName = "kobanSensorV1"
    static let syncMaxBatchBytes = 524_288
    static let syncMaxBatchEvents = 500
    static let syncCheckInIntervalSeconds = 60
    static let syncRetryBaseSeconds = 15
    static let syncRetryBackoffMultiplier = 2
    static let syncRetryMaxSeconds = 1800
    static let syncOutboxMaxBytes = 262_144_000
    static let projectMaxDepth = 5
    static let projectMaxDirectoriesVisited = 20000
    static let projectMaxFilesMatched = 5000
    static let projectMaxWallClockSeconds = 30
    static let homeSignalMaxDepth = 8
    static let homeSignalMaxDirectoriesVisited = 50000
    static let homeSignalMaxFilesVisited = 250_000
    static let homeSignalMaxWallClockSeconds = 60
    static let directoryListingMaxEntries = 25000
    static let agentConfigMaxFilesPerDirectory = 5000
    static let agentConfigMaxEntriesVisitedPerDirectory = 25000
    static let agentConfigMaxWallClockSeconds = 10
    static let agentConfigMaxFileBytes = 5_000_000
    static let packageMetadataMaxFileBytes = 25_000_000
    static let pythonRequirementMaxIncludedFiles = 250
    static let pythonRequirementMaxIncludeDepth = 16
    static let homebrewReceiptMaxFileBytes = 1_000_000
    static let configurationMaxFileBytes = 1_000_000
    static let fileHashReadChunkBytes = 1_048_576
    /// FSEvents coalescing latency for the config-file watcher: short, since edits are rare and a
    /// prompt UI refresh matters more than batching.
    static let configurationWatchLatencySeconds: TimeInterval = 0.3
}
