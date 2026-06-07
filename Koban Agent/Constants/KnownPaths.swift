import Foundation

/// Filesystem locations Koban watches and reads. The single home for path literals;
/// no path string may appear inline anywhere else (see CLAUDE.md).
enum KnownPaths {
    /// Homebrew prefixes in priority order: Apple Silicon first, Intel fallback.
    /// Only the prefixes that actually exist on disk are monitored.
    static let homebrewPrefixes: [String] = ["/opt/homebrew", "/usr/local"]

    static let homebrewCellarComponent = "Cellar"
    static let homebrewCaskroomComponent = "Caskroom"
    static let homebrewMetadataComponent = ".metadata"
    static let homebrewInstallReceiptName = "INSTALL_RECEIPT.json"

    /// User-scope Claude configuration file, relative to the home directory.
    static let claudeUserConfigComponent = ".claude.json"
    static let claudeDirectoryComponent = ".claude"
    static let claudeSettingsName = "settings.json"
    static let claudeLocalSettingsName = "settings.local.json"
    static let claudeAgentsComponent = "agents"
    static let claudeCommandsComponent = "commands"
    static let claudeSkillsComponent = "skills"
    static let claudeInstructionsName = "CLAUDE.md"
    static let claudeLocalInstructionsName = "CLAUDE.local.md"

    static let codexDirectoryComponent = ".codex"
    static let codexConfigName = "config.toml"
    static let codexHooksName = "hooks.json"
    static let codexRulesComponent = "rules"
    static let codexRuleFileExtension = "rules"
    static let codexSystemConfigPath = "/etc/codex/config.toml"
    static let agentsDirectoryComponent = ".agents"
    static let agentSkillsComponent = "skills"
    static let agentSkillFileName = "SKILL.md"

    static let homePathPrefix = "~/"
    static let homePath = "~"
    static let cursorDirectoryComponent = ".cursor"
    static let cursorMCPName = "mcp.json"
    static let cursorRulesComponent = "rules"
    static let cursorRuleFileExtension = "mdc"
    static let cursorLegacyRulesName = ".cursorrules"
    static let cursorInstructionNames = ["AGENTS.md"]

    static let configDirectoryPath = ".config"
    static let openCodeDirectoryComponent = "opencode"
    static let openCodeProjectDirectoryComponent = ".opencode"
    static let openCodeConfigNames = ["opencode.json", "opencode.jsonc"]
    static let openCodeAgentDirectoryNames = ["agent", "agents"]
    static let openCodeCommandDirectoryNames = ["command", "commands"]
    static let openCodePluginDirectoryNames = ["plugin", "plugins"]
    static let openCodeInstructionNames = ["AGENTS.md", "Agents.md"]
    static let managedPreferencesDirectoryPath = "/Library/Managed Preferences"
    static let openCodeManagedPreferenceName = "ai.opencode.managed.plist"
    static let markdownFileExtension = "md"
    static let mcpConfigName = "mcp.json"
    static let sharedMCPDirectoryComponent = "mcp"
    static let sharedProjectMCPName = ".mcp.json"
    static let piDirectoryComponent = ".pi"
    static let piAgentDirectoryComponent = "agent"
    static let piProjectDirectoryComponent = ".pi"
    static let settingsJSONName = "settings.json"
    static let piExtensionsComponent = "extensions"
    static let packageJSONName = "package.json"

    /// The user's home directory.
    static func homeDirectory() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    /// Existing Homebrew prefixes, as directory URLs.
    static func existingHomebrewPrefixes() -> [URL] {
        homebrewPrefixes
            .map { URL(filePath: $0, directoryHint: .isDirectory) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// The user-scope Claude configuration file URL.
    static func claudeUserConfig() -> URL {
        homeDirectory().appending(component: claudeUserConfigComponent)
    }

    static func codexUserConfig() -> URL {
        homeDirectory()
            .appending(component: codexDirectoryComponent, directoryHint: .isDirectory)
            .appending(component: codexConfigName)
    }

    static func codexSystemConfig() -> URL {
        URL(filePath: codexSystemConfigPath)
    }

    static func codexSystemDirectory() -> URL {
        codexSystemConfig().deletingLastPathComponent()
    }

    static func codexSystemHooks() -> URL {
        codexSystemDirectory()
            .appending(component: codexHooksName)
    }

    static func codexSystemRulesDirectory() -> URL {
        codexSystemDirectory()
            .appending(component: codexRulesComponent, directoryHint: .isDirectory)
    }

    static func codexSystemSkillsDirectory() -> URL {
        codexSystemDirectory()
            .appending(component: agentSkillsComponent, directoryHint: .isDirectory)
    }

    static func openCodeSystemManagedPreference() -> URL {
        URL(filePath: managedPreferencesDirectoryPath, directoryHint: .isDirectory)
            .appending(component: openCodeManagedPreferenceName)
    }

    static func openCodeUserManagedPreference() -> URL {
        URL(filePath: managedPreferencesDirectoryPath, directoryHint: .isDirectory)
            .appending(component: NSUserName(), directoryHint: .isDirectory)
            .appending(component: openCodeManagedPreferenceName)
    }

    static func configuredURL(_ path: String, directoryHint: URL.DirectoryHint = .inferFromPath) -> URL {
        if path == homePath {
            return homeDirectory()
        }
        if path.hasPrefix(homePathPrefix) {
            return homeDirectory()
                .appending(path: String(path.dropFirst(homePathPrefix.count)), directoryHint: directoryHint)
        }
        return URL(filePath: path, directoryHint: directoryHint)
    }
}
