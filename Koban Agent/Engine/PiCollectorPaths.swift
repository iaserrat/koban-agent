import Foundation

/// Resolves Pi config paths from Koban settings.
enum PiCollectorPaths {
    static func mcpConfigURLs(_ configuration: KobanConfiguration) -> [URL] {
        let settings = configuration.pi
        var urls: [URL] = []
        if settings.includeSharedGlobalMCP {
            urls.append(sharedGlobalMCPURL())
        }
        if settings.includePiGlobalOverride {
            urls.append(piAgentDirectory(settings).appending(component: KnownPaths.mcpConfigName))
        }
        if settings.includeSharedProjectMCP {
            urls.append(contentsOf: projectRootURLs(configuration).map {
                $0.appending(component: KnownPaths.sharedProjectMCPName)
            })
        }
        if settings.includePiProjectOverride {
            urls.append(contentsOf: projectRootURLs(configuration).map {
                $0
                    .appending(component: KnownPaths.piProjectDirectoryComponent, directoryHint: .isDirectory)
                    .appending(component: KnownPaths.mcpConfigName)
            })
        }
        return urls
    }

    static func settingsURLs(_ configuration: KobanConfiguration) -> [URL] {
        let settings = configuration.pi
        let globalSettings = piAgentDirectory(settings).appending(component: KnownPaths.settingsJSONName)
        let projectSettings = projectRootURLs(configuration).map {
            $0
                .appending(component: KnownPaths.piProjectDirectoryComponent, directoryHint: .isDirectory)
                .appending(component: KnownPaths.settingsJSONName)
        }
        return [globalSettings] + projectSettings
    }

    static func packageDirectories(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.pi.includePackages else { return [] }
        return [
            piAgentDirectory(configuration.pi)
                .appending(component: KnownPaths.piExtensionsComponent, directoryHint: .isDirectory)
        ]
    }

    private static func sharedGlobalMCPURL() -> URL {
        KnownPaths.homeDirectory()
            .appending(path: KnownPaths.configDirectoryPath, directoryHint: .isDirectory)
            .appending(component: KnownPaths.sharedMCPDirectoryComponent, directoryHint: .isDirectory)
            .appending(component: KnownPaths.mcpConfigName)
    }

    private static func piAgentDirectory(_ settings: PiSettings) -> URL {
        settings.agentDirectory.map { KnownPaths.configuredURL($0, directoryHint: .isDirectory) }
            ?? KnownPaths.homeDirectory()
            .appending(component: KnownPaths.piDirectoryComponent, directoryHint: .isDirectory)
            .appending(component: KnownPaths.piAgentDirectoryComponent, directoryHint: .isDirectory)
    }

    private static func projectRootURLs(_ configuration: KobanConfiguration) -> [URL] {
        configuration.watch.projectDiscovery.roots.map {
            KnownPaths.configuredURL($0, directoryHint: .isDirectory)
        }
    }
}
