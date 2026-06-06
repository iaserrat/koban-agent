import Foundation

struct HomeSignalWatchPlanner {
    func plan(
        settings: HomeSignalScanSettings,
        enabledSurfaces: Set<MonitoredSurface>
    ) throws -> HomeSignalWatchPlan {
        guard settings.enabled else {
            return HomeSignalWatchPlan(interests: [], issues: [])
        }
        guard settings.eventPathFiltering else {
            return HomeSignalWatchPlan(
                interests: broadInterests(settings: settings, enabledSurfaces: enabledSurfaces),
                issues: []
            )
        }
        let discovery = try SignalFileDiscoverer(settings: settings).candidateFileResult()
        let interests = interests(
            for: discovery.files,
            enabledSurfaces: enabledSurfaces
        )
        return HomeSignalWatchPlan(interests: interests, issues: discovery.issues)
    }

    private func broadInterests(
        settings: HomeSignalScanSettings,
        enabledSurfaces: Set<MonitoredSurface>
    ) -> [WatchInterest] {
        let root = KnownPaths.configuredURL(settings.root, directoryHint: .isDirectory).path
        return enabledSurfaces.map { surface in
            WatchInterest(surface: surface, paths: [root])
        }
    }

    private func interests(
        for files: [URL],
        enabledSurfaces: Set<MonitoredSurface>
    ) -> [WatchInterest] {
        let pathsBySurface = files.reduce(into: [MonitoredSurface: [String]]()) { result, file in
            for surface in surfaces(for: file).intersection(enabledSurfaces) {
                result[surface, default: []].append(file.path)
            }
        }
        return pathsBySurface.map { surface, paths in
            WatchInterest(surface: surface, paths: paths)
        }
    }

    private func surfaces(for url: URL) -> Set<MonitoredSurface> {
        let name = url.lastPathComponent
        let components = Set(url.pathComponents)
        var surfaces: Set<MonitoredSurface> = []
        appendAgentConfigSurfaces(name: name, components: components, to: &surfaces)
        appendPackageSurfaces(name: name, to: &surfaces)
        return surfaces
    }

    private func appendAgentConfigSurfaces(
        name: String,
        components: Set<String>,
        to surfaces: inout Set<MonitoredSurface>
    ) {
        let isClaudeSignal = components.contains(KnownPaths.claudeDirectoryComponent)
            || name == KnownPaths.claudeUserConfigComponent
            || name == KnownPaths.claudeInstructionsName
            || name == KnownPaths.claudeLocalInstructionsName
        if isClaudeSignal {
            surfaces.insert(.claudeConfig)
        }
        let isCodexSignal = components.contains(KnownPaths.codexDirectoryComponent)
            || components.contains(KnownPaths.agentsDirectoryComponent)
            || name.hasSuffix("." + KnownPaths.codexRuleFileExtension)
        if isCodexSignal {
            surfaces.insert(.codexConfig)
        }
        let isCursorSignal = components.contains(KnownPaths.cursorDirectoryComponent)
            || name == KnownPaths.cursorLegacyRulesName
            || name.hasSuffix("." + KnownPaths.cursorRuleFileExtension)
            || KnownPaths.cursorInstructionNames.contains(name)
        if isCursorSignal {
            surfaces.insert(.cursorConfig)
        }
        let isOpenCodeSignal = components.contains(KnownPaths.openCodeProjectDirectoryComponent)
            || components.contains(KnownPaths.openCodeDirectoryComponent)
            || KnownPaths.openCodeConfigNames.contains(name)
            || KnownPaths.openCodeInstructionNames.contains(name)
        if isOpenCodeSignal {
            surfaces.insert(.opencodeConfig)
        }
        if components.contains(KnownPaths.piDirectoryComponent) {
            surfaces.insert(.piConfig)
        }
    }

    private func appendPackageSurfaces(name: String, to surfaces: inout Set<MonitoredSurface>) {
        if PackageMetadataNames.javascriptLockfiles.contains(name) {
            surfaces.insert(.javascriptPackages)
        }
        let isPythonSignal = name == PackageMetadataNames.uvLockName
            || name == PackageMetadataNames.pyprojectName
            || name == PackageMetadataNames.pylockName
            || FilenameMatcher.matches(
                name: name,
                exactNames: [],
                globs: PackageMetadataNames.pythonRequirementGlobs
            )
        if isPythonSignal {
            surfaces.insert(.pythonPackages)
        }
    }
}
