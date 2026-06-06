import Foundation

/// Claude configuration collection settings.
struct ClaudeSettings: Codable, Hashable {
    var enabled: Bool
    var configPath: String?
    var projectRoots: [String]?
    var includeProjectMCP: Bool
    var includeSettings: Bool
    var includeAgents: Bool
    var includeCommands: Bool
    var includeHooks: Bool
    var includeSkills: Bool
    var includePlugins: Bool
    var includeInstructions: Bool
    var includeManagedSettings: Bool

    init(
        enabled: Bool,
        configPath: String?,
        projectRoots: [String]?,
        includeProjectMCP: Bool,
        includeSettings: Bool,
        includeAgents: Bool,
        includeCommands: Bool,
        includeHooks: Bool,
        includeSkills: Bool,
        includePlugins: Bool,
        includeInstructions: Bool,
        includeManagedSettings: Bool
    ) {
        self.enabled = enabled
        self.configPath = configPath
        self.projectRoots = projectRoots
        self.includeProjectMCP = includeProjectMCP
        self.includeSettings = includeSettings
        self.includeAgents = includeAgents
        self.includeCommands = includeCommands
        self.includeHooks = includeHooks
        self.includeSkills = includeSkills
        self.includePlugins = includePlugins
        self.includeInstructions = includeInstructions
        self.includeManagedSettings = includeManagedSettings
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.claude
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        configPath = try container.decodeIfPresent(String.self, forKey: .configPath) ?? defaults.configPath
        projectRoots = try container.decodeIfPresent([String].self, forKey: .projectRoots) ?? defaults
            .projectRoots
        includeProjectMCP = try container.decodeIfPresent(
            Bool.self,
            forKey: .includeProjectMCP
        ) ?? defaults.includeProjectMCP
        includeSettings = try container.decodeIfPresent(Bool.self, forKey: .includeSettings) ?? defaults
            .includeSettings
        includeAgents = try container.decodeIfPresent(Bool.self, forKey: .includeAgents) ?? defaults
            .includeAgents
        includeCommands = try container.decodeIfPresent(Bool.self, forKey: .includeCommands) ?? defaults
            .includeCommands
        includeHooks = try container.decodeIfPresent(Bool.self, forKey: .includeHooks) ?? defaults
            .includeHooks
        includeSkills = try container.decodeIfPresent(Bool.self, forKey: .includeSkills) ?? defaults
            .includeSkills
        includePlugins = try container.decodeIfPresent(Bool.self, forKey: .includePlugins) ?? defaults
            .includePlugins
        includeInstructions = try container.decodeIfPresent(
            Bool.self,
            forKey: .includeInstructions
        ) ?? defaults.includeInstructions
        includeManagedSettings = try container.decodeIfPresent(
            Bool.self,
            forKey: .includeManagedSettings
        ) ?? defaults.includeManagedSettings
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case configPath
        case projectRoots
        case includeProjectMCP
        case includeSettings
        case includeAgents
        case includeCommands
        case includeHooks
        case includeSkills
        case includePlugins
        case includeInstructions
        case includeManagedSettings
    }
}
