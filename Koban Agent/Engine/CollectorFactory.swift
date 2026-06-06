import Foundation

/// Builds the set of collectors a configuration asks for, resolving prefixes/paths against the
/// defaults when the config leaves them unset.
enum CollectorFactory {
    static func make(for configuration: KobanConfiguration) throws -> [any SurfaceCollector] {
        var collectors: [any SurfaceCollector] = []

        collectors.append(contentsOf: homebrewCollectors(configuration))
        collectors.append(contentsOf: claudeCollectors(configuration))
        try collectors.append(contentsOf: codexCollectors(configuration))
        collectors.append(contentsOf: cursorCollectors(configuration))
        collectors.append(contentsOf: openCodeCollectors(configuration))
        collectors.append(contentsOf: piCollectors(configuration))
        collectors.append(contentsOf: PackageCollectorFactory.javascriptCollectors(configuration))
        collectors.append(contentsOf: PackageCollectorFactory.pythonCollectors(configuration))
        return collectors
    }

    private static func homebrewCollectors(_ configuration: KobanConfiguration) -> [any SurfaceCollector] {
        guard configuration.homebrew.enabled else { return [] }
        return [HomebrewCollector(prefixes: homebrewPrefixes(configuration.homebrew))]
    }

    private static func claudeCollectors(_ configuration: KobanConfiguration) -> [any SurfaceCollector] {
        guard configuration.claude.enabled else { return [] }
        return [
            ClaudeConfigCollector(
                configURLs: ClaudeCollectorPaths.configURLs(configuration),
                settingsURLs: ClaudeCollectorPaths.settingsURLs(configuration),
                customizationDirectories: ClaudeCollectorPaths.customizationDirectories(configuration),
                instructionURLs: ClaudeCollectorPaths.instructionURLs(configuration),
                pluginURLs: ClaudeCollectorPaths.pluginURLs(configuration),
                includeHooks: configuration.claude.includeHooks,
                includePlugins: configuration.claude.includePlugins
            )
        ]
    }

    private static func codexCollectors(
        _ configuration: KobanConfiguration
    ) throws -> [any SurfaceCollector] {
        guard configuration.codex.enabled else { return [] }
        let profileConfig = try CodexProfileConfigDiscoverer.result(for: configuration.codex)
        return [
            CodexConfigCollector(
                configURLs: codexConfigURLs(configuration.codex, profileConfigURLs: profileConfig.files),
                hooksURLs: codexHooksURLs(configuration.codex),
                rulesDirectories: codexRulesDirectories(configuration.codex),
                skillsDirectories: codexSkillsDirectories(configuration.codex),
                initialIssues: profileConfig.issues
            )
        ]
    }

    private static func cursorCollectors(_ configuration: KobanConfiguration) -> [any SurfaceCollector] {
        guard configuration.cursor.enabled else { return [] }
        return [
            CursorConfigCollector(
                mcpConfigURLs: CursorCollectorPaths.mcpURLs(configuration),
                rulesDirectories: CursorCollectorPaths.rulesDirectories(configuration),
                legacyRuleURLs: CursorCollectorPaths.legacyRuleURLs(configuration),
                instructionURLs: CursorCollectorPaths.instructionURLs(configuration)
            )
        ]
    }

    private static func openCodeCollectors(_ configuration: KobanConfiguration) -> [any SurfaceCollector] {
        guard configuration.opencode.enabled else { return [] }
        return [
            OpenCodeConfigCollector(
                configURLs: OpenCodeCollectorPaths.configURLs(configuration),
                agentDirectories: OpenCodeCollectorPaths.agentDirectories(configuration),
                commandDirectories: OpenCodeCollectorPaths.commandDirectories(configuration),
                pluginDirectories: OpenCodeCollectorPaths.pluginDirectories(configuration),
                instructionURLs: OpenCodeCollectorPaths.instructionURLs(configuration),
                includeMCP: configuration.opencode.includeMCP
            )
        ]
    }

    private static func piCollectors(_ configuration: KobanConfiguration) -> [any SurfaceCollector] {
        guard configuration.pi.enabled else { return [] }
        return [
            PiConfigCollector(
                mcpConfigURLs: PiCollectorPaths.mcpConfigURLs(configuration),
                settingsURLs: PiCollectorPaths.settingsURLs(configuration),
                packageDirectories: PiCollectorPaths.packageDirectories(configuration),
                includeImports: configuration.pi.includeImports
            )
        ]
    }

    private static func homebrewPrefixes(_ settings: HomebrewSettings) -> [URL] {
        guard let prefixes = settings.prefixes else {
            return KnownPaths.existingHomebrewPrefixes()
        }
        return prefixes.map { KnownPaths.configuredURL($0, directoryHint: .isDirectory) }
    }

    private static func codexConfigURLs(
        _ settings: CodexSettings,
        profileConfigURLs: [URL]
    ) -> [URL] {
        let userConfigURL = settings.userConfigPath.map { KnownPaths.configuredURL($0) }
            ?? KnownPaths.codexUserConfig()
        let projectConfigURLs = (settings.projectRoots ?? []).map { root in
            KnownPaths.configuredURL(root, directoryHint: .isDirectory)
                .appending(component: KnownPaths.codexDirectoryComponent, directoryHint: .isDirectory)
                .appending(component: KnownPaths.codexConfigName)
        }
        let systemConfigURLs = settings.includeSystemConfig ? [KnownPaths.codexSystemConfig()] : []
        return [userConfigURL] + profileConfigURLs + projectConfigURLs + systemConfigURLs
    }

    private static func codexHooksURLs(_ settings: CodexSettings) -> [URL] {
        guard settings.includeHooks else { return [] }
        return codexBaseDirectories(settings).map {
            $0.appending(component: KnownPaths.codexHooksName)
        }
    }

    private static func codexRulesDirectories(_ settings: CodexSettings) -> [URL] {
        guard settings.includeRules else { return [] }
        return codexBaseDirectories(settings).map {
            $0.appending(component: KnownPaths.codexRulesComponent, directoryHint: .isDirectory)
        }
    }

    private static func codexSkillsDirectories(_ settings: CodexSettings) -> [URL] {
        guard settings.includeSkills else { return [] }
        let userSkillDirectories = [
            KnownPaths.homeDirectory()
                .appending(component: KnownPaths.agentsDirectoryComponent, directoryHint: .isDirectory)
                .appending(component: KnownPaths.agentSkillsComponent, directoryHint: .isDirectory)
        ]
        let projectSkillDirectories = (settings.projectRoots ?? []).map { root in
            KnownPaths.configuredURL(root, directoryHint: .isDirectory)
                .appending(component: KnownPaths.agentsDirectoryComponent, directoryHint: .isDirectory)
                .appending(component: KnownPaths.agentSkillsComponent, directoryHint: .isDirectory)
        }
        let systemSkills = settings.includeSystemConfig ? [KnownPaths.codexSystemSkillsDirectory()] : []
        return userSkillDirectories + projectSkillDirectories + systemSkills
    }

    private static func codexBaseDirectories(_ settings: CodexSettings) -> [URL] {
        let userConfigURL = settings.userConfigPath.map { KnownPaths.configuredURL($0) }
            ?? KnownPaths.codexUserConfig()
        let userBaseDirectory = userConfigURL.deletingLastPathComponent()
        let projectBaseDirectories = (settings.projectRoots ?? []).map { root in
            KnownPaths.configuredURL(root, directoryHint: .isDirectory)
                .appending(component: KnownPaths.codexDirectoryComponent, directoryHint: .isDirectory)
        }
        let systemBases = settings.includeSystemConfig ? [KnownPaths.codexSystemDirectory()] : []
        return [userBaseDirectory] + projectBaseDirectories + systemBases
    }
}
