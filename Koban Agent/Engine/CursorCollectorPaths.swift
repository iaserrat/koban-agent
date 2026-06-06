import Foundation

/// Resolves Cursor config paths from Koban settings.
enum CursorCollectorPaths {
    static func mcpURLs(_ configuration: KobanConfiguration) -> [URL] {
        let settings = configuration.cursor
        var urls: [URL] = []
        if settings.includeGlobalMCP {
            let globalURL = settings.globalMCPPath.map { KnownPaths.configuredURL($0) }
                ?? KnownPaths.homeDirectory()
                .appending(component: KnownPaths.cursorDirectoryComponent, directoryHint: .isDirectory)
                .appending(component: KnownPaths.cursorMCPName)
            urls.append(globalURL)
        }
        if settings.includeProjectMCP {
            urls.append(contentsOf: projectBaseDirectories(configuration).map {
                $0.appending(component: KnownPaths.cursorMCPName)
            })
        }
        return urls
    }

    static func rulesDirectories(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.cursor.includeRules else { return [] }
        return projectBaseDirectories(configuration).map {
            $0.appending(component: KnownPaths.cursorRulesComponent, directoryHint: .isDirectory)
        }
    }

    static func legacyRuleURLs(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.cursor.includeLegacyRules else { return [] }
        return projectRootURLs(configuration).map {
            $0.appending(component: KnownPaths.cursorLegacyRulesName)
        }
    }

    static func instructionURLs(_ configuration: KobanConfiguration) -> [URL] {
        guard configuration.cursor.includeInstructions else { return [] }
        return projectRootURLs(configuration).flatMap { root in
            KnownPaths.cursorInstructionNames.map { root.appending(component: $0) }
        }
    }

    private static func projectBaseDirectories(_ configuration: KobanConfiguration) -> [URL] {
        projectRootURLs(configuration).map {
            $0.appending(component: KnownPaths.cursorDirectoryComponent, directoryHint: .isDirectory)
        }
    }

    private static func projectRootURLs(_ configuration: KobanConfiguration) -> [URL] {
        configuration.watch.projectDiscovery.roots.map {
            KnownPaths.configuredURL($0, directoryHint: .isDirectory)
        }
    }
}
