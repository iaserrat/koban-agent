import Foundation

/// Hard limits for opt-in broad discovery passes.
struct ScanBudgetSettings: Codable, Hashable {
    var maxDirectoriesVisited: Int
    var maxFilesVisited: Int
    var maxWallClockSeconds: Int

    init(
        maxDirectoriesVisited: Int,
        maxFilesVisited: Int,
        maxWallClockSeconds: Int
    ) {
        self.maxDirectoriesVisited = maxDirectoriesVisited
        self.maxFilesVisited = maxFilesVisited
        self.maxWallClockSeconds = maxWallClockSeconds
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaultValue
        maxDirectoriesVisited = try container.decodeIfPresent(
            Int.self,
            forKey: .maxDirectoriesVisited
        ) ?? defaults.maxDirectoriesVisited
        maxFilesVisited = try container.decodeIfPresent(Int.self, forKey: .maxFilesVisited)
            ?? defaults.maxFilesVisited
        maxWallClockSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .maxWallClockSeconds
        ) ?? defaults.maxWallClockSeconds
    }

    static let defaultValue = Self(
        maxDirectoriesVisited: ConfigurationDefaults.homeSignalMaxDirectoriesVisited,
        maxFilesVisited: ConfigurationDefaults.homeSignalMaxFilesVisited,
        maxWallClockSeconds: ConfigurationDefaults.homeSignalMaxWallClockSeconds
    )

    private enum CodingKeys: String, CodingKey {
        case maxDirectoriesVisited
        case maxFilesVisited
        case maxWallClockSeconds
    }
}
