import Foundation
import Testing
@testable import Koban_Agent

// MARK: - CodexProfileConfigDiscovererTests

struct CodexProfileConfigDiscovererTests {
    @Test
    func resultReturnsSortedMatchingProfileConfigs() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let codexDirectory = directory.appending(path: ".codex")
            try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
            let beta = codexDirectory.appending(path: "beta.config.toml")
            let alpha = codexDirectory.appending(path: "alpha.config.toml")
            try Data().write(to: beta)
            try Data().write(to: alpha)
            try Data().write(to: codexDirectory.appending(path: "ignore.toml"))

            let result = try CodexProfileConfigDiscoverer.result(
                matching: codexDirectory.appending(path: "*.config.toml").path
            )

            #expect(result.files.map(\.lastPathComponent) == [
                "alpha.config.toml",
                "beta.config.toml"
            ])
            #expect(result.issues.isEmpty)
        }
    }

    @Test
    func resultStopsAtEntryLimitAndReportsIssue() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let codexDirectory = directory.appending(path: ".codex")
            try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
            try Data().write(to: codexDirectory.appending(path: "alpha.config.toml"))
            try Data().write(to: codexDirectory.appending(path: "beta.config.toml"))

            let result = try CodexProfileConfigDiscoverer.result(
                matching: codexDirectory.appending(path: "*.config.toml").path,
                maxEntries: 1
            )

            #expect(result.files.count == 1)
            #expect(result.issues == [
                CollectorIssue(
                    path: codexDirectory.path,
                    reason: HealthMessages.directoryEnumerationEntryLimitReached(maxEntries: 1)
                )
            ])
        }
    }

    @Test
    func cancelledTaskStopsDiscovery() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let codexDirectory = directory.appending(path: ".codex")
            try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
            try Data().write(to: codexDirectory.appending(path: "alpha.config.toml"))

            let task = Task {
                withUnsafeCurrentTask { task in
                    task?.cancel()
                }
                return try CodexProfileConfigDiscoverer.result(
                    matching: codexDirectory.appending(path: "*.config.toml").path
                )
            }

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }
}
