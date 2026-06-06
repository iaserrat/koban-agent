import Foundation

/// The built-in configuration: sensible watch timings and the default ruleset. This is what
/// runs when there is no `~/.config/koban/koban.yaml`, and what a user file is merged onto.
/// It is the single source of default behaviour, mirrored for humans in `koban.default.yaml`.
enum DefaultConfiguration {
    static let value = KobanConfiguration(
        watch: WatchSettings(
            debounceMilliseconds: ConfigurationDefaults.debounceMilliseconds,
            pollIntervalSeconds: ConfigurationDefaults.pollIntervalSeconds,
            maxScanWallClockSeconds: ConfigurationDefaults.maxScanWallClockSeconds,
            maxFreshScanAgeSeconds: ConfigurationDefaults.maxFreshScanAgeSeconds,
            projectDiscovery: .defaultValue,
            homeSignalScan: .defaultValue
        ),
        persistence: PersistenceSettings(
            maxStoredEvents: ConfigurationDefaults.maxStoredEvents,
            maxStoredFindings: ConfigurationDefaults.maxStoredFindings
        ),
        sync: SyncSettings(
            enabled: ConfigurationDefaults.syncEnabled,
            protocolName: ConfigurationDefaults.syncProtocolName,
            endpoint: nil,
            enrollmentToken: nil,
            sensorToken: nil,
            tenantID: nil,
            deviceID: nil,
            maxBatchBytes: ConfigurationDefaults.syncMaxBatchBytes,
            maxBatchEvents: ConfigurationDefaults.syncMaxBatchEvents,
            checkInIntervalSeconds: ConfigurationDefaults.syncCheckInIntervalSeconds,
            retryBaseSeconds: ConfigurationDefaults.syncRetryBaseSeconds,
            retryMaxSeconds: ConfigurationDefaults.syncRetryMaxSeconds,
            outboxMaxBytes: ConfigurationDefaults.syncOutboxMaxBytes
        ),
        homebrew: HomebrewSettings(enabled: true, prefixes: nil),
        claude: ClaudeSettings(
            enabled: true,
            configPath: nil,
            projectRoots: nil,
            includeProjectMCP: true,
            includeSettings: true,
            includeAgents: true,
            includeCommands: true,
            includeHooks: true,
            includeSkills: true,
            includePlugins: true,
            includeInstructions: true,
            includeManagedSettings: false
        ),
        codex: CodexSettings(
            enabled: true,
            userConfigPath: nil,
            profileConfigGlob: nil,
            projectRoots: nil,
            includeSystemConfig: false,
            includeSkills: true,
            includeHooks: true,
            includeRules: true
        ),
        pi: PiSettings(
            enabled: true,
            agentDirectory: nil,
            includeSharedGlobalMCP: true,
            includeSharedProjectMCP: true,
            includePiGlobalOverride: true,
            includePiProjectOverride: true,
            includePackages: true,
            includeImports: true
        ),
        cursor: CursorSettings(
            enabled: true,
            globalMCPPath: nil,
            includeGlobalMCP: true,
            includeProjectMCP: true,
            includeRules: true,
            includeLegacyRules: true,
            includeInstructions: true
        ),
        opencode: OpenCodeSettings(
            enabled: true,
            userConfigDirectory: nil,
            projectRoots: nil,
            includeGlobal: true,
            includeProject: true,
            includeMCP: true,
            includeAgents: true,
            includeCommands: true,
            includePlugins: true,
            includeInstructions: true,
            includeManagedPreferences: false
        ),
        javascript: JavaScriptPackageSettings(
            enabled: true,
            projectRoots: nil,
            maxDepth: nil,
            includeNpm: true,
            includePnpm: true,
            includeYarn: true,
            includeBun: true,
            excludeDirectories: nil,
            lockfileNames: PackageMetadataNames.javascriptLockfiles
        ),
        python: PythonPackageSettings(
            enabled: true,
            projectRoots: nil,
            maxDepth: nil,
            includeUV: true,
            includePyProject: true,
            includeRequirements: true,
            includePylock: true,
            excludeDirectories: nil,
            requirementFileGlobs: PackageMetadataNames.pythonRequirementGlobs
        ),
        rules: DefaultHeuristicRules.value
    )
}
