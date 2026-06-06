import Foundation

/// Pi configuration collection settings.
struct PiSettings: Codable, Hashable {
    var enabled: Bool
    var agentDirectory: String?
    var includeSharedGlobalMCP: Bool
    var includeSharedProjectMCP: Bool
    var includePiGlobalOverride: Bool
    var includePiProjectOverride: Bool
    var includePackages: Bool
    var includeImports: Bool

    init(
        enabled: Bool,
        agentDirectory: String?,
        includeSharedGlobalMCP: Bool,
        includeSharedProjectMCP: Bool,
        includePiGlobalOverride: Bool,
        includePiProjectOverride: Bool,
        includePackages: Bool,
        includeImports: Bool
    ) {
        self.enabled = enabled
        self.agentDirectory = agentDirectory
        self.includeSharedGlobalMCP = includeSharedGlobalMCP
        self.includeSharedProjectMCP = includeSharedProjectMCP
        self.includePiGlobalOverride = includePiGlobalOverride
        self.includePiProjectOverride = includePiProjectOverride
        self.includePackages = includePackages
        self.includeImports = includeImports
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.pi
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        agentDirectory = try container.decodeIfPresent(String.self, forKey: .agentDirectory)
            ?? defaults.agentDirectory
        includeSharedGlobalMCP = try container.decodeIfPresent(
            Bool.self,
            forKey: .includeSharedGlobalMCP
        ) ?? defaults.includeSharedGlobalMCP
        includeSharedProjectMCP = try container.decodeIfPresent(
            Bool.self,
            forKey: .includeSharedProjectMCP
        ) ?? defaults.includeSharedProjectMCP
        includePiGlobalOverride = try container.decodeIfPresent(
            Bool.self,
            forKey: .includePiGlobalOverride
        ) ?? defaults.includePiGlobalOverride
        includePiProjectOverride = try container.decodeIfPresent(
            Bool.self,
            forKey: .includePiProjectOverride
        ) ?? defaults.includePiProjectOverride
        includePackages = try container.decodeIfPresent(Bool.self, forKey: .includePackages)
            ?? defaults.includePackages
        includeImports = try container.decodeIfPresent(Bool.self, forKey: .includeImports)
            ?? defaults.includeImports
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case agentDirectory
        case includeSharedGlobalMCP
        case includeSharedProjectMCP
        case includePiGlobalOverride
        case includePiProjectOverride
        case includePackages
        case includeImports
    }
}
