import Foundation

/// Opt-in targeted discovery under the user's home directory.
struct HomeSignalScanSettings: Codable, Hashable {
    var enabled: Bool
    var root: String
    var maxDepth: Int
    var followSymlinks: Bool
    var eventPathFiltering: Bool
    var initialScanBudget: ScanBudgetSettings
    var signalFileNames: [String]
    var signalFileGlobs: [String]
    var pruneDirectoryNames: [String]

    init(
        enabled: Bool,
        root: String,
        maxDepth: Int,
        followSymlinks: Bool,
        eventPathFiltering: Bool,
        initialScanBudget: ScanBudgetSettings,
        signalFileNames: [String],
        signalFileGlobs: [String],
        pruneDirectoryNames: [String]
    ) {
        self.enabled = enabled
        self.root = root
        self.maxDepth = maxDepth
        self.followSymlinks = followSymlinks
        self.eventPathFiltering = eventPathFiltering
        self.initialScanBudget = initialScanBudget
        self.signalFileNames = signalFileNames
        self.signalFileGlobs = signalFileGlobs
        self.pruneDirectoryNames = pruneDirectoryNames
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaultValue
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        root = try container.decodeIfPresent(String.self, forKey: .root) ?? defaults.root
        maxDepth = try container.decodeIfPresent(Int.self, forKey: .maxDepth) ?? defaults.maxDepth
        followSymlinks = try container.decodeIfPresent(
            Bool.self,
            forKey: .followSymlinks
        ) ?? defaults.followSymlinks
        eventPathFiltering = try container.decodeIfPresent(
            Bool.self,
            forKey: .eventPathFiltering
        ) ?? defaults.eventPathFiltering
        initialScanBudget = try container.decodeIfPresent(
            ScanBudgetSettings.self,
            forKey: .initialScanBudget
        ) ?? defaults.initialScanBudget
        let signalNames = try Self.decodeSignalNames(from: container, defaults: defaults)
        signalFileNames = signalNames.files
        signalFileGlobs = signalNames.globs
        pruneDirectoryNames = signalNames.prunes
    }

    private static func decodeSignalNames(
        from container: KeyedDecodingContainer<CodingKeys>,
        defaults: Self
    ) throws -> HomeSignalNames {
        let files = try container.decodeIfPresent(
            [String].self,
            forKey: .signalFileNames
        ) ?? defaults.signalFileNames
        let globs = try container.decodeIfPresent(
            [String].self,
            forKey: .signalFileGlobs
        ) ?? defaults.signalFileGlobs
        let prunes = try container.decodeIfPresent(
            [String].self,
            forKey: .pruneDirectoryNames
        ) ?? defaults.pruneDirectoryNames
        return HomeSignalNames(files: files, globs: globs, prunes: prunes)
    }

    static let defaultValue = Self(
        enabled: false,
        root: DiscoveryNames.homeRoot,
        maxDepth: ConfigurationDefaults.homeSignalMaxDepth,
        followSymlinks: false,
        eventPathFiltering: true,
        initialScanBudget: .defaultValue,
        signalFileNames: DiscoveryNames.homeSignalFileNames,
        signalFileGlobs: DiscoveryNames.homeSignalFileGlobs,
        pruneDirectoryNames: DiscoveryNames.defaultExcludeDirectories
            + DiscoveryNames.protectedUserDirectories
    )

    private enum CodingKeys: String, CodingKey {
        case enabled
        case root
        case maxDepth
        case followSymlinks
        case eventPathFiltering
        case initialScanBudget
        case signalFileNames
        case signalFileGlobs
        case pruneDirectoryNames
    }
}
