import Foundation

enum ClaudeCollectorPaths {
    static func configURLs(_ configuration: KobanConfiguration) -> [URL] {
        let settings = configuration.claude
        let userConfigURL = settings.configPath.map { KnownPaths.configuredURL($0) }
            ?? KnownPaths.claudeUserConfig()
        guard settings.includeProjectMCP else { return [userConfigURL] }
        return [userConfigURL] + projectRoots(configuration).map {
            $0.appending(component: KnownPaths.sharedProjectMCPName)
        }
    }

    static func settingsURLs(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.claude.includeSettings else { return [] }
        let directory = KnownPaths.homeDirectory()
            .appending(component: KnownPaths.claudeDirectoryComponent, directoryHint: .isDirectory)
        var urls = [
            directory.appending(component: KnownPaths.claudeSettingsName),
            directory.appending(component: KnownPaths.claudeLocalSettingsName)
        ]
        urls.append(contentsOf: projectSettingsURLs(configuration))
        if configuration.claude.includeManagedSettings {
            urls.append(URL(filePath: ClaudeConfigNames.managedSettingsPath))
        }
        return urls
    }

    static func customizationDirectories(_ config: KobanConfiguration) -> [ClaudeCustomizationDirectory] {
        let userClaudeDirectory = KnownPaths.homeDirectory()
            .appending(component: KnownPaths.claudeDirectoryComponent, directoryHint: .isDirectory)
        var directories = customizationDirectories(config, baseDirectory: userClaudeDirectory)
        directories.append(contentsOf: projectRoots(config).flatMap { root in
            let projectClaudeDirectory = root.appending(
                component: KnownPaths.claudeDirectoryComponent,
                directoryHint: .isDirectory
            )
            return customizationDirectories(config, baseDirectory: projectClaudeDirectory)
        })
        return directories
    }

    static func instructionURLs(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.claude.includeInstructions else { return [] }
        let userClaudeDirectory = KnownPaths.homeDirectory()
            .appending(component: KnownPaths.claudeDirectoryComponent, directoryHint: .isDirectory)
        return [
            userClaudeDirectory.appending(component: KnownPaths.claudeInstructionsName)
        ] + projectRoots(configuration).flatMap(projectInstructionURLs)
    }

    static func pluginURLs(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.claude.includePlugins else { return [] }
        let directory = KnownPaths.homeDirectory()
            .appending(component: KnownPaths.claudeDirectoryComponent, directoryHint: .isDirectory)
            .appending(component: ClaudeConfigNames.pluginsDirectoryComponent, directoryHint: .isDirectory)
        return [
            directory.appending(component: ClaudeConfigNames.knownMarketplacesName),
            directory.appending(component: ClaudeConfigNames.installedPluginsName)
        ]
    }

    private static func projectSettingsURLs(_ configuration: KobanConfiguration) -> [URL] {
        projectRoots(configuration).flatMap { root in
            let directory = root.appending(
                component: KnownPaths.claudeDirectoryComponent,
                directoryHint: .isDirectory
            )
            return [
                directory.appending(component: KnownPaths.claudeSettingsName),
                directory.appending(component: KnownPaths.claudeLocalSettingsName)
            ]
        }
    }

    private static func customizationDirectories(
        _ configuration: KobanConfiguration,
        baseDirectory: URL
    ) -> [ClaudeCustomizationDirectory] {
        var directories: [ClaudeCustomizationDirectory] = []
        if configuration.claude.includeAgents {
            directories.append(directory(
                baseDirectory,
                component: KnownPaths.claudeAgentsComponent,
                kind: .agent
            ))
        }
        if configuration.claude.includeCommands {
            directories.append(directory(
                baseDirectory,
                component: KnownPaths.claudeCommandsComponent,
                kind: .command
            ))
        }
        if configuration.claude.includeSkills {
            directories.append(directory(
                baseDirectory,
                component: KnownPaths.claudeSkillsComponent,
                kind: .skill
            ))
        }
        return directories
    }

    private static func directory(
        _ baseDirectory: URL,
        component: String,
        kind: InventoryKind
    ) -> ClaudeCustomizationDirectory {
        ClaudeCustomizationDirectory(
            url: baseDirectory.appending(component: component, directoryHint: .isDirectory),
            kind: kind
        )
    }

    private static func projectInstructionURLs(_ root: URL) -> [URL] {
        [
            root.appending(component: KnownPaths.claudeInstructionsName),
            root.appending(component: KnownPaths.claudeLocalInstructionsName),
            root
                .appending(
                    component: KnownPaths.claudeDirectoryComponent,
                    directoryHint: .isDirectory
                )
                .appending(component: KnownPaths.claudeInstructionsName)
        ]
    }

    private static func projectRoots(_ configuration: KobanConfiguration) -> [URL] {
        (configuration.claude.projectRoots ?? configuration.watch.projectDiscovery.roots).map {
            KnownPaths.configuredURL($0, directoryHint: .isDirectory)
        }
    }
}
