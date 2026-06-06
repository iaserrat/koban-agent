import Foundation

/// OpenCode configuration collection settings.
struct OpenCodeSettings: Codable, Hashable {
    var enabled: Bool
    var userConfigDirectory: String?
    var projectRoots: [String]?
    var includeGlobal: Bool
    var includeProject: Bool
    var includeMCP: Bool
    var includeAgents: Bool
    var includeCommands: Bool
    var includePlugins: Bool
    var includeInstructions: Bool
    var includeManagedPreferences: Bool

    init(
        enabled: Bool,
        userConfigDirectory: String?,
        projectRoots: [String]?,
        includeGlobal: Bool,
        includeProject: Bool,
        includeMCP: Bool,
        includeAgents: Bool,
        includeCommands: Bool,
        includePlugins: Bool,
        includeInstructions: Bool,
        includeManagedPreferences: Bool
    ) {
        self.enabled = enabled
        self.userConfigDirectory = userConfigDirectory
        self.projectRoots = projectRoots
        self.includeGlobal = includeGlobal
        self.includeProject = includeProject
        self.includeMCP = includeMCP
        self.includeAgents = includeAgents
        self.includeCommands = includeCommands
        self.includePlugins = includePlugins
        self.includeInstructions = includeInstructions
        self.includeManagedPreferences = includeManagedPreferences
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.opencode
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        userConfigDirectory = try container.decodeIfPresent(String.self, forKey: .userConfigDirectory)
            ?? defaults.userConfigDirectory
        projectRoots = try container.decodeIfPresent([String].self, forKey: .projectRoots)
            ?? defaults.projectRoots
        includeGlobal = try container.decodeIfPresent(Bool.self, forKey: .includeGlobal)
            ?? defaults.includeGlobal
        includeProject = try container.decodeIfPresent(Bool.self, forKey: .includeProject)
            ?? defaults.includeProject
        includeMCP = try container.decodeIfPresent(Bool.self, forKey: .includeMCP)
            ?? defaults.includeMCP
        includeAgents = try container.decodeIfPresent(Bool.self, forKey: .includeAgents)
            ?? defaults.includeAgents
        includeCommands = try container.decodeIfPresent(Bool.self, forKey: .includeCommands)
            ?? defaults.includeCommands
        includePlugins = try container.decodeIfPresent(Bool.self, forKey: .includePlugins)
            ?? defaults.includePlugins
        includeInstructions = try container.decodeIfPresent(Bool.self, forKey: .includeInstructions)
            ?? defaults.includeInstructions
        includeManagedPreferences = try container.decodeIfPresent(
            Bool.self,
            forKey: .includeManagedPreferences
        ) ?? defaults.includeManagedPreferences
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case userConfigDirectory
        case projectRoots
        case includeGlobal
        case includeProject
        case includeMCP
        case includeAgents
        case includeCommands
        case includePlugins
        case includeInstructions
        case includeManagedPreferences
    }
}
