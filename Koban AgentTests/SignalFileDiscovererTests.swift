import Foundation
import Testing
@testable import Koban_Agent

struct SignalFileDiscovererTests {
    @Test
    func findsSignalFilesWithoutScanningPrunedUserFolders() async throws {
        try await Fixture.withTemporaryDirectory { root in
            try writeFile(root.appending(path: ".claude/settings.json"))
            try writeFile(root.appending(path: "Documents/.claude/settings.json"))
            try writeFile(root.appending(path: "node_modules/.claude/settings.json"))

            let settings = HomeSignalScanSettings(
                enabled: true,
                root: root.path,
                maxDepth: ConfigurationDefaults.homeSignalMaxDepth,
                followSymlinks: false,
                eventPathFiltering: true,
                initialScanBudget: .defaultValue,
                signalFileNames: ["settings.json"],
                signalFileGlobs: [],
                pruneDirectoryNames: ["Documents", "node_modules"]
            )

            let paths = try SignalFileDiscoverer(settings: settings)
                .candidateFiles()
                .map { $0.resolvingSymlinksInPath().path }

            let expected = root.appending(path: ".claude/settings.json")
                .resolvingSymlinksInPath()
                .path
            #expect(paths == [expected])
        }
    }

    @Test
    func stopsWhenFileBudgetIsReached() async throws {
        try await Fixture.withTemporaryDirectory { root in
            try writeFile(root.appending(path: "one/AGENTS.md"))
            try writeFile(root.appending(path: "two/AGENTS.md"))

            let settings = HomeSignalScanSettings(
                enabled: true,
                root: root.path,
                maxDepth: ConfigurationDefaults.homeSignalMaxDepth,
                followSymlinks: false,
                eventPathFiltering: true,
                initialScanBudget: ScanBudgetSettings(
                    maxDirectoriesVisited: 100,
                    maxFilesVisited: 1,
                    maxWallClockSeconds: 60
                ),
                signalFileNames: ["AGENTS.md"],
                signalFileGlobs: [],
                pruneDirectoryNames: []
            )

            let result = try SignalFileDiscoverer(settings: settings).candidateFileResult()
            #expect(result.files.count == 1)
            #expect(result.issues.count == 1)
            #expect(result.issues.first?.reason == HealthMessages.directoryEnumerationLimitReached(
                maxEntries: settings.initialScanBudget.maxDirectoriesVisited,
                maxFiles: settings.initialScanBudget.maxFilesVisited
            ))
        }
    }

    @Test
    func invalidEnabledRootReportsIssue() async throws {
        try await Fixture.withTemporaryDirectory { root in
            let missingRoot = root.appending(path: "missing")
            let settings = HomeSignalScanSettings(
                enabled: true,
                root: missingRoot.path,
                maxDepth: ConfigurationDefaults.homeSignalMaxDepth,
                followSymlinks: false,
                eventPathFiltering: true,
                initialScanBudget: .defaultValue,
                signalFileNames: [KnownPaths.claudeSettingsName],
                signalFileGlobs: [],
                pruneDirectoryNames: []
            )

            let result = try SignalFileDiscoverer(settings: settings).candidateFileResult()

            #expect(result.files.isEmpty)
            #expect(result.issues.count == 1)
            #expect(result.issues.first?.path == missingRoot.path)
            #expect(
                result.issues.first?.reason.hasPrefix(HealthMessages.directoryEnumerationUnavailable) == true
            )
        }
    }

    @Test
    func stopsWhenWallClockBudgetIsReached() async throws {
        try await Fixture.withTemporaryDirectory { root in
            try writeFile(root.appending(path: KnownPaths.claudeInstructionsName))
            var tick = 0
            let start = Date(timeIntervalSince1970: 0)
            let settings = HomeSignalScanSettings(
                enabled: true,
                root: root.path,
                maxDepth: ConfigurationDefaults.homeSignalMaxDepth,
                followSymlinks: false,
                eventPathFiltering: true,
                initialScanBudget: ScanBudgetSettings(
                    maxDirectoriesVisited: 100,
                    maxFilesVisited: 100,
                    maxWallClockSeconds: 1
                ),
                signalFileNames: [KnownPaths.claudeInstructionsName],
                signalFileGlobs: [],
                pruneDirectoryNames: []
            )

            let result = try SignalFileDiscoverer(settings: settings) {
                defer { tick += 1 }
                return start.addingTimeInterval(tick == 0 ? 0 : 2)
            }.candidateFileResult()

            #expect(result.files.isEmpty)
            #expect(result.issues.count == 1)
            #expect(result.issues.first?.reason == HealthMessages.directoryEnumerationTimeLimitReached(
                seconds: settings.initialScanBudget.maxWallClockSeconds
            ))
        }
    }

    @Test
    func cancelledTaskStopsSearch() async throws {
        try await Fixture.withTemporaryDirectory { root in
            try writeFile(root.appending(path: KnownPaths.claudeInstructionsName))
            let settings = HomeSignalScanSettings(
                enabled: true,
                root: root.path,
                maxDepth: ConfigurationDefaults.homeSignalMaxDepth,
                followSymlinks: false,
                eventPathFiltering: true,
                initialScanBudget: .defaultValue,
                signalFileNames: [KnownPaths.claudeInstructionsName],
                signalFileGlobs: [],
                pruneDirectoryNames: []
            )

            let task = Task {
                withUnsafeCurrentTask { task in
                    task?.cancel()
                }
                return try SignalFileDiscoverer(settings: settings).candidateFileResult()
            }

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }

    private func writeFile(_ url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: url)
    }
}
