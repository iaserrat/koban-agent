import Foundation

/// Cursor configuration collection settings.
struct CursorSettings: Codable, Hashable {
    var enabled: Bool
    var globalMCPPath: String?
    var includeGlobalMCP: Bool
    var includeProjectMCP: Bool
    var includeRules: Bool
    var includeLegacyRules: Bool
    var includeInstructions: Bool

    init(
        enabled: Bool,
        globalMCPPath: String?,
        includeGlobalMCP: Bool,
        includeProjectMCP: Bool,
        includeRules: Bool,
        includeLegacyRules: Bool,
        includeInstructions: Bool
    ) {
        self.enabled = enabled
        self.globalMCPPath = globalMCPPath
        self.includeGlobalMCP = includeGlobalMCP
        self.includeProjectMCP = includeProjectMCP
        self.includeRules = includeRules
        self.includeLegacyRules = includeLegacyRules
        self.includeInstructions = includeInstructions
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.cursor
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        globalMCPPath = try container.decodeIfPresent(String.self, forKey: .globalMCPPath)
            ?? defaults.globalMCPPath
        includeGlobalMCP = try container.decodeIfPresent(Bool.self, forKey: .includeGlobalMCP)
            ?? defaults.includeGlobalMCP
        includeProjectMCP = try container.decodeIfPresent(Bool.self, forKey: .includeProjectMCP)
            ?? defaults.includeProjectMCP
        includeRules = try container.decodeIfPresent(Bool.self, forKey: .includeRules)
            ?? defaults.includeRules
        includeLegacyRules = try container.decodeIfPresent(Bool.self, forKey: .includeLegacyRules)
            ?? defaults.includeLegacyRules
        includeInstructions = try container.decodeIfPresent(Bool.self, forKey: .includeInstructions)
            ?? defaults.includeInstructions
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case globalMCPPath
        case includeGlobalMCP
        case includeProjectMCP
        case includeRules
        case includeLegacyRules
        case includeInstructions
    }
}
