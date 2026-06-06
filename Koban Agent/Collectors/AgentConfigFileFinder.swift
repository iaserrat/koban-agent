import Foundation

/// Shared bounded file enumeration for agent customization directories.
enum AgentConfigFileFinder {
    static func files(
        in directory: URL,
        matching fileExtension: String,
        maxFiles: Int = ConfigurationDefaults.agentConfigMaxFilesPerDirectory,
        maxEntries: Int = ConfigurationDefaults.agentConfigMaxEntriesVisitedPerDirectory,
        maxWallClockSeconds: Int = ConfigurationDefaults.agentConfigMaxWallClockSeconds,
        now: @escaping @Sendable () -> Date = Date.init
    ) throws -> AgentConfigFileSearchResult {
        let budget = AgentConfigFileSearchBudget(
            maxFiles: maxFiles,
            maxEntries: maxEntries,
            maxWallClockSeconds: maxWallClockSeconds
        )
        let result = try AgentConfigFileSearcher(directory: directory, budget: budget, now: now).run()
        return AgentConfigFileSearchResult(
            files: result.files.filter { $0.pathExtension == fileExtension },
            issues: result.issues
        )
    }

    static func files(
        in directory: URL,
        named fileName: String,
        maxFiles: Int = ConfigurationDefaults.agentConfigMaxFilesPerDirectory,
        maxEntries: Int = ConfigurationDefaults.agentConfigMaxEntriesVisitedPerDirectory,
        maxWallClockSeconds: Int = ConfigurationDefaults.agentConfigMaxWallClockSeconds,
        now: @escaping @Sendable () -> Date = Date.init
    ) throws -> AgentConfigFileSearchResult {
        let budget = AgentConfigFileSearchBudget(
            maxFiles: maxFiles,
            maxEntries: maxEntries,
            maxWallClockSeconds: maxWallClockSeconds
        )
        let result = try AgentConfigFileSearcher(directory: directory, budget: budget, now: now).run()
        return AgentConfigFileSearchResult(
            files: result.files.filter { $0.lastPathComponent == fileName },
            issues: result.issues
        )
    }
}
