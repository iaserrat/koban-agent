import Foundation

/// Resolves OpenCode config paths from Koban settings.
enum OpenCodeCollectorPaths {
    static func configURLs(_ configuration: KobanConfiguration) -> [URL] {
        var urls = configDirectories(configuration).flatMap { directory in
            KnownPaths.openCodeConfigNames.map { directory.appending(component: $0) }
        }
        if configuration.opencode.includeManagedPreferences {
            urls.append(KnownPaths.openCodeUserManagedPreference())
            urls.append(KnownPaths.openCodeSystemManagedPreference())
        }
        return urls
    }

    static func agentDirectories(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.opencode.includeAgents else { return [] }
        return configDirectories(configuration).flatMap { directory in
            KnownPaths.openCodeAgentDirectoryNames.map {
                directory.appending(component: $0, directoryHint: .isDirectory)
            }
        }
    }

    static func commandDirectories(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.opencode.includeCommands else { return [] }
        return configDirectories(configuration).flatMap { directory in
            KnownPaths.openCodeCommandDirectoryNames.map {
                directory.appending(component: $0, directoryHint: .isDirectory)
            }
        }
    }

    static func pluginDirectories(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.opencode.includePlugins else { return [] }
        return configDirectories(configuration).flatMap { directory in
            KnownPaths.openCodePluginDirectoryNames.map {
                directory.appending(component: $0, directoryHint: .isDirectory)
            }
        }
    }

    static func instructionURLs(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.opencode.includeInstructions else { return [] }
        return configDirectories(configuration).flatMap { directory in
            KnownPaths.openCodeInstructionNames.map { directory.appending(component: $0) }
        }
    }

    private static func configDirectories(_ configuration: KobanConfiguration) -> [URL] {
        var directories: [URL] = []
        if configuration.opencode.includeGlobal {
            directories.append(globalConfigDirectory(configuration.opencode))
        }
        if configuration.opencode.includeProject {
            directories.append(contentsOf: projectConfigDirectories(configuration))
        }
        return directories
    }

    private static func globalConfigDirectory(_ settings: OpenCodeSettings) -> URL {
        settings.userConfigDirectory.map { KnownPaths.configuredURL($0, directoryHint: .isDirectory) }
            ?? KnownPaths.homeDirectory()
            .appending(path: KnownPaths.configDirectoryPath, directoryHint: .isDirectory)
            .appending(component: KnownPaths.openCodeDirectoryComponent, directoryHint: .isDirectory)
    }

    private static func projectConfigDirectories(_ configuration: KobanConfiguration) -> [URL] {
        let roots = configuration.opencode.projectRoots ?? configuration.watch.projectDiscovery.roots
        return roots.map {
            KnownPaths.configuredURL($0, directoryHint: .isDirectory)
                .appending(
                    component: KnownPaths.openCodeProjectDirectoryComponent,
                    directoryHint: .isDirectory
                )
        }
    }
}
