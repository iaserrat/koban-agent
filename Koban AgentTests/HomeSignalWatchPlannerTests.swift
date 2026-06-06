import Foundation
import Testing
@testable import Koban_Agent

struct HomeSignalWatchPlannerTests {
    @Test
    func mapsDiscoveredSignalFilesToRelevantSurfaces() async throws {
        try await Fixture.withTemporaryDirectory { root in
            let claudeInstructions = root.appending(path: KnownPaths.claudeInstructionsName)
            let packageLock = root.appending(path: "app/package-lock.json")
            let pyproject = root.appending(path: "service/pyproject.toml")
            try writeFile(claudeInstructions)
            try writeFile(packageLock)
            try writeFile(pyproject)

            let plan = try HomeSignalWatchPlanner().plan(
                settings: settings(root: root.path),
                enabledSurfaces: [.claudeConfig, .javascriptPackages, .pythonPackages]
            )

            #expect(plan.issues.isEmpty)
            #expect(fileNames(for: .claudeConfig, in: plan) == [claudeInstructions.lastPathComponent])
            #expect(fileNames(for: .javascriptPackages, in: plan) == [packageLock.lastPathComponent])
            #expect(fileNames(for: .pythonPackages, in: plan) == [pyproject.lastPathComponent])
        }
    }

    @Test
    func preservesDiscoveryIssues() async throws {
        try await Fixture.withTemporaryDirectory { root in
            let missingRoot = root.appending(path: "missing")

            let plan = try HomeSignalWatchPlanner().plan(
                settings: settings(root: missingRoot.path),
                enabledSurfaces: [.claudeConfig]
            )

            #expect(plan.interests.isEmpty)
            #expect(plan.issues.count == 1)
            #expect(plan.issues.first?.path == missingRoot.path)
        }
    }

    @Test
    func disabledScanProducesNoInterests() async throws {
        try await Fixture.withTemporaryDirectory { root in
            var scanSettings = settings(root: root.path)
            scanSettings.enabled = false

            let plan = try HomeSignalWatchPlanner().plan(
                settings: scanSettings,
                enabledSurfaces: [.claudeConfig]
            )

            #expect(plan.interests.isEmpty)
            #expect(plan.issues.isEmpty)
        }
    }

    @Test
    func disabledEventPathFilteringWatchesRootForEnabledSurfaces() async throws {
        try await Fixture.withTemporaryDirectory { root in
            var scanSettings = settings(root: root.path)
            scanSettings.eventPathFiltering = false

            let plan = try HomeSignalWatchPlanner().plan(
                settings: scanSettings,
                enabledSurfaces: [.claudeConfig, .javascriptPackages]
            )

            #expect(Set(plan.interests.map(\.surface)) == [.claudeConfig, .javascriptPackages])
            #expect(Set(plan.interests.flatMap(\.paths)) == [root.path])
            #expect(plan.issues.isEmpty)
        }
    }

    private func paths(for surface: MonitoredSurface, in plan: HomeSignalWatchPlan) -> [String] {
        plan.interests
            .filter { $0.surface == surface }
            .flatMap(\.paths)
            .sorted()
    }

    private func fileNames(for surface: MonitoredSurface, in plan: HomeSignalWatchPlan) -> [String] {
        paths(for: surface, in: plan)
            .map { URL(filePath: $0).lastPathComponent }
    }

    private func settings(root: String) -> HomeSignalScanSettings {
        HomeSignalScanSettings(
            enabled: true,
            root: root,
            maxDepth: ConfigurationDefaults.homeSignalMaxDepth,
            followSymlinks: false,
            eventPathFiltering: true,
            initialScanBudget: .defaultValue,
            signalFileNames: DiscoveryNames.homeSignalFileNames,
            signalFileGlobs: DiscoveryNames.homeSignalFileGlobs,
            pruneDirectoryNames: []
        )
    }

    private func writeFile(_ url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: url)
    }
}
