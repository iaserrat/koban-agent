import Foundation

/// Codex configuration collection settings.
struct CodexSettings: Codable, Hashable {
    var enabled: Bool
    var userConfigPath: String?
    var profileConfigGlob: String?
    var projectRoots: [String]?
    var includeSystemConfig: Bool
    var includeSkills: Bool
    var includeHooks: Bool
    var includeRules: Bool

    init(
        enabled: Bool,
        userConfigPath: String?,
        profileConfigGlob: String?,
        projectRoots: [String]?,
        includeSystemConfig: Bool,
        includeSkills: Bool,
        includeHooks: Bool,
        includeRules: Bool
    ) {
        self.enabled = enabled
        self.userConfigPath = userConfigPath
        self.profileConfigGlob = profileConfigGlob
        self.projectRoots = projectRoots
        self.includeSystemConfig = includeSystemConfig
        self.includeSkills = includeSkills
        self.includeHooks = includeHooks
        self.includeRules = includeRules
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.codex
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        userConfigPath = try container.decodeIfPresent(String.self, forKey: .userConfigPath)
            ?? defaults.userConfigPath
        profileConfigGlob = try container.decodeIfPresent(String.self, forKey: .profileConfigGlob)
            ?? defaults.profileConfigGlob
        projectRoots = try container.decodeIfPresent([String].self, forKey: .projectRoots)
            ?? defaults.projectRoots
        includeSystemConfig = try container.decodeIfPresent(
            Bool.self,
            forKey: .includeSystemConfig
        ) ?? defaults.includeSystemConfig
        includeSkills = try container.decodeIfPresent(Bool.self, forKey: .includeSkills)
            ?? defaults.includeSkills
        includeHooks = try container.decodeIfPresent(Bool.self, forKey: .includeHooks)
            ?? defaults.includeHooks
        includeRules = try container.decodeIfPresent(Bool.self, forKey: .includeRules)
            ?? defaults.includeRules
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case userConfigPath
        case profileConfigGlob
        case projectRoots
        case includeSystemConfig
        case includeSkills
        case includeHooks
        case includeRules
    }
}
