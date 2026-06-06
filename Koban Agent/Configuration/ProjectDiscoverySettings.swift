import Foundation

/// Bounded project-root discovery used by package and project-scoped agent collectors.
struct ProjectDiscoverySettings: Codable, Hashable {
    var roots: [String]
    var maxDepth: Int
    var excludeDirectories: [String]

    init(roots: [String], maxDepth: Int, excludeDirectories: [String]) {
        self.roots = roots
        self.maxDepth = maxDepth
        self.excludeDirectories = excludeDirectories
    }

    init(from decoder: any Decoder) throws {
        try self.init(from: decoder, defaults: Self.defaultValue)
    }

    init(from decoder: any Decoder, defaults: Self) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roots = try container.decodeIfPresent([String].self, forKey: .projectRoots) ?? defaults.roots
        maxDepth = try container.decodeIfPresent(Int.self, forKey: .maxDepth) ?? defaults.maxDepth
        excludeDirectories = try container.decodeIfPresent(
            [String].self,
            forKey: .excludeDirectories
        ) ?? defaults.excludeDirectories
    }

    /// Explicit because `roots` maps to the `projectRoots` key (a rename), which blocks
    /// synthesis. Encodes into the encoder's own container so `WatchSettings` can flatten these
    /// keys into `watch` by handing us its shared encoder (mirrors `init(from:defaults:)`).
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(roots, forKey: .projectRoots)
        try container.encode(maxDepth, forKey: .maxDepth)
        try container.encode(excludeDirectories, forKey: .excludeDirectories)
    }

    static let defaultValue = Self(
        roots: DiscoveryNames.defaultProjectRoots,
        maxDepth: ConfigurationDefaults.projectMaxDepth,
        excludeDirectories: DiscoveryNames.defaultExcludeDirectories
    )

    private enum CodingKeys: String, CodingKey {
        case projectRoots
        case maxDepth
        case excludeDirectories
    }
}
