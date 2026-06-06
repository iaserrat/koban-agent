import Foundation

/// Python dependency metadata inventory settings.
struct PythonPackageSettings: Codable, Hashable {
    var enabled: Bool
    var projectRoots: [String]?
    var maxDepth: Int?
    var includeUV: Bool
    var includePyProject: Bool
    var includeRequirements: Bool
    var includePylock: Bool
    var excludeDirectories: [String]?
    var requirementFileGlobs: [String]

    init(
        enabled: Bool,
        projectRoots: [String]?,
        maxDepth: Int?,
        includeUV: Bool,
        includePyProject: Bool,
        includeRequirements: Bool,
        includePylock: Bool,
        excludeDirectories: [String]?,
        requirementFileGlobs: [String]
    ) {
        self.enabled = enabled
        self.projectRoots = projectRoots
        self.maxDepth = maxDepth
        self.includeUV = includeUV
        self.includePyProject = includePyProject
        self.includeRequirements = includeRequirements
        self.includePylock = includePylock
        self.excludeDirectories = excludeDirectories
        self.requirementFileGlobs = requirementFileGlobs
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.python
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        projectRoots = try container.decodeIfPresent([String].self, forKey: .projectRoots)
            ?? defaults.projectRoots
        maxDepth = try container.decodeIfPresent(Int.self, forKey: .maxDepth) ?? defaults.maxDepth
        includeUV = try container.decodeIfPresent(Bool.self, forKey: .includeUV)
            ?? defaults.includeUV
        includePyProject = try container.decodeIfPresent(Bool.self, forKey: .includePyProject)
            ?? defaults.includePyProject
        includeRequirements = try container.decodeIfPresent(
            Bool.self,
            forKey: .includeRequirements
        ) ?? defaults.includeRequirements
        includePylock = try container.decodeIfPresent(Bool.self, forKey: .includePylock)
            ?? defaults.includePylock
        excludeDirectories = try container.decodeIfPresent([String].self, forKey: .excludeDirectories)
            ?? defaults.excludeDirectories
        requirementFileGlobs = try container.decodeIfPresent(
            [String].self,
            forKey: .requirementFileGlobs
        ) ?? defaults.requirementFileGlobs
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case projectRoots
        case maxDepth
        case includeUV
        case includePyProject
        case includeRequirements
        case includePylock
        case excludeDirectories
        case requirementFileGlobs
    }
}
