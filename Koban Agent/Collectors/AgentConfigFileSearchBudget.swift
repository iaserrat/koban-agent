struct AgentConfigFileSearchBudget {
    var maxFiles: Int
    var maxEntries: Int
    var maxWallClockSeconds: Int

    static let defaultValue = Self(
        maxFiles: ConfigurationDefaults.agentConfigMaxFilesPerDirectory,
        maxEntries: ConfigurationDefaults.agentConfigMaxEntriesVisitedPerDirectory,
        maxWallClockSeconds: ConfigurationDefaults.agentConfigMaxWallClockSeconds
    )
}
