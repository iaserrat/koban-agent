import Foundation

/// JavaScript package-lock inventory settings.
struct JavaScriptPackageSettings: Codable, Hashable {
    var enabled: Bool
    var projectRoots: [String]?
    var maxDepth: Int?
    var includeNpm: Bool
    var includePnpm: Bool
    var includeYarn: Bool
    var includeBun: Bool
    var excludeDirectories: [String]?
    var lockfileNames: [String]

    init(
        enabled: Bool,
        projectRoots: [String]?,
        maxDepth: Int?,
        includeNpm: Bool,
        includePnpm: Bool,
        includeYarn: Bool,
        includeBun: Bool,
        excludeDirectories: [String]?,
        lockfileNames: [String]
    ) {
        self.enabled = enabled
        self.projectRoots = projectRoots
        self.maxDepth = maxDepth
        self.includeNpm = includeNpm
        self.includePnpm = includePnpm
        self.includeYarn = includeYarn
        self.includeBun = includeBun
        self.excludeDirectories = excludeDirectories
        self.lockfileNames = lockfileNames
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.javascript
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        projectRoots = try container.decodeIfPresent([String].self, forKey: .projectRoots)
            ?? defaults.projectRoots
        maxDepth = try container.decodeIfPresent(Int.self, forKey: .maxDepth) ?? defaults.maxDepth
        includeNpm = try container.decodeIfPresent(Bool.self, forKey: .includeNpm)
            ?? defaults.includeNpm
        includePnpm = try container.decodeIfPresent(Bool.self, forKey: .includePnpm)
            ?? defaults.includePnpm
        includeYarn = try container.decodeIfPresent(Bool.self, forKey: .includeYarn)
            ?? defaults.includeYarn
        includeBun = try container.decodeIfPresent(Bool.self, forKey: .includeBun)
            ?? defaults.includeBun
        excludeDirectories = try container.decodeIfPresent([String].self, forKey: .excludeDirectories)
            ?? defaults.excludeDirectories
        lockfileNames = try container.decodeIfPresent([String].self, forKey: .lockfileNames)
            ?? defaults.lockfileNames
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case projectRoots
        case maxDepth
        case includeNpm
        case includePnpm
        case includeYarn
        case includeBun
        case excludeDirectories
        case lockfileNames
    }
}
