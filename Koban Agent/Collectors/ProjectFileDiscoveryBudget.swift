struct ProjectFileDiscoveryBudget {
    var maxDirectoriesVisited: Int
    var maxFilesMatched: Int
    var maxWallClockSeconds: Int

    static let defaultValue = Self(
        maxDirectoriesVisited: ConfigurationDefaults.projectMaxDirectoriesVisited,
        maxFilesMatched: ConfigurationDefaults.projectMaxFilesMatched,
        maxWallClockSeconds: ConfigurationDefaults.projectMaxWallClockSeconds
    )
}
