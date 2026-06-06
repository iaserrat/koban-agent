import Foundation
@testable import Koban_Agent

// MARK: - Collector factory configuration fixtures

func normalizedPaths(_ paths: [String]) -> Set<String> {
    Set(paths.map { normalizedPath(URL(filePath: $0)) })
}

func normalizedPath(_ url: URL) -> String {
    url.standardizedFileURL.path
}

func optInPathConfiguration(codexDirectory directory: URL) -> KobanConfiguration {
    var config = DefaultConfiguration.value
    config.homebrew.enabled = false
    config.claude.enabled = false
    config.pi.enabled = false
    config.cursor.enabled = false
    config.javascript.enabled = false
    config.python.enabled = false
    config.codex = CodexSettings(
        enabled: true,
        userConfigPath: directory.appending(path: ".codex/config.toml").path,
        profileConfigGlob: directory.appending(path: ".codex/*.config.toml").path,
        projectRoots: [],
        includeSystemConfig: true,
        includeSkills: true,
        includeHooks: true,
        includeRules: true
    )
    config.opencode = OpenCodeSettings(
        enabled: true,
        userConfigDirectory: nil,
        projectRoots: [],
        includeGlobal: false,
        includeProject: false,
        includeMCP: true,
        includeAgents: false,
        includeCommands: false,
        includePlugins: false,
        includeInstructions: false,
        includeManagedPreferences: true
    )
    return config
}
