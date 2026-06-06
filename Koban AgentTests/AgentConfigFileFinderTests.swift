import Foundation
import Testing
@testable import Koban_Agent

struct AgentConfigFileFinderTests {
    @Test
    func recordsInvalidDirectoryIssueWithoutDroppingReadableFiles() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let visible = directory.appending(component: "visible.md")
            try "visible".write(to: visible, atomically: true, encoding: .utf8)

            let visibleResult = try AgentConfigFileFinder.files(
                in: directory,
                matching: KnownPaths.markdownFileExtension
            )

            let invalidResult = try AgentConfigFileFinder.files(
                in: visible,
                matching: KnownPaths.markdownFileExtension
            )

            #expect(visibleResult.files.map(\.lastPathComponent) == ["visible.md"])
            #expect(visibleResult.issues.isEmpty)
            #expect(invalidResult.files.isEmpty)
            #expect(invalidResult.issues == [
                CollectorIssue(
                    path: visible.path,
                    reason: HealthMessages.directoryEnumerationUnavailable
                )
            ])
        }
    }

    @Test
    func stopsAtFileBudgetAndRecordsIssue() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let maxFiles = 2
            try writeMarkdownFiles(count: maxFiles + 1, in: directory)

            let result = try AgentConfigFileFinder.files(
                in: directory,
                matching: KnownPaths.markdownFileExtension,
                maxFiles: maxFiles,
                maxEntries: 10,
                maxWallClockSeconds: ConfigurationDefaults.agentConfigMaxWallClockSeconds
            )

            #expect(result.files.count == maxFiles)
            #expect(result.issues == [
                CollectorIssue(
                    path: directory.path,
                    reason: HealthMessages.directoryEnumerationLimitReached(
                        maxEntries: 10,
                        maxFiles: maxFiles
                    )
                )
            ])
        }
    }

    @Test
    func stopsAtWallClockBudgetAndRecordsIssue() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let clock = ProjectFileDiscoveryTestClock()
            try writeMarkdownFiles(count: 2, in: directory)

            let result = try AgentConfigFileFinder.files(
                in: directory,
                matching: KnownPaths.markdownFileExtension,
                maxFiles: ConfigurationDefaults.agentConfigMaxFilesPerDirectory,
                maxEntries: ConfigurationDefaults.agentConfigMaxEntriesVisitedPerDirectory,
                maxWallClockSeconds: 1,
                now: clock.now
            )

            #expect(result.issues == [
                CollectorIssue(
                    path: directory.path,
                    reason: HealthMessages.directoryEnumerationTimeLimitReached(seconds: 1)
                )
            ])
        }
    }

    @Test
    func cancelledTaskStopsSearch() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeMarkdownFiles(count: 1, in: directory)

            let task = Task {
                withUnsafeCurrentTask { task in
                    task?.cancel()
                }
                return try AgentConfigFileFinder.files(
                    in: directory,
                    matching: KnownPaths.markdownFileExtension
                )
            }

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }

    private func writeMarkdownFiles(count: Int, in directory: URL) throws {
        for index in 0 ..< count {
            let url = directory.appending(component: "file-\(index).md")
            try "visible".write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
