import Foundation
import Testing
@testable import Koban_Agent

// MARK: - ProjectFileDiscovererTests

struct ProjectFileDiscovererTests {
    @Test
    func findsIncludedFilesInsideDepthAndSkipsExcludedDirectories() async throws {
        try await Fixture.withTemporaryDirectory { root in
            try writeFile(root.appending(path: "app/package-lock.json"))
            try writeFile(root.appending(path: "app/node_modules/package-lock.json"))
            try writeFile(root.appending(path: "app/deep/one/two/three/package-lock.json"))

            let discoverer = ProjectFileDiscoverer(
                roots: [root.path],
                includeFileNames: ["package-lock.json"],
                includeFileGlobs: [],
                excludeDirectoryNames: ["node_modules"],
                maxDepth: 3
            )

            let paths = try discoverer.candidateFiles().map(\.lastPathComponent)
            #expect(paths == ["package-lock.json"])
        }
    }

    @Test
    func supportsSimpleFilenameGlobs() async throws {
        try await Fixture.withTemporaryDirectory { root in
            try writeFile(root.appending(path: "requirements-dev.txt"))
            try writeFile(root.appending(path: "notes.txt"))

            let discoverer = ProjectFileDiscoverer(
                roots: [root.path],
                includeFileNames: [],
                includeFileGlobs: ["requirements*.txt"],
                excludeDirectoryNames: [],
                maxDepth: 1
            )

            let paths = try discoverer.candidateFiles().map(\.lastPathComponent)
            #expect(paths == ["requirements-dev.txt"])
        }
    }

    @Test
    func recordsInvalidRootIssueWithoutThrowing() async throws {
        try await Fixture.withTemporaryDirectory { root in
            let fileRoot = root.appending(path: "not-a-directory")
            try writeFile(fileRoot)

            let discoverer = ProjectFileDiscoverer(
                roots: [fileRoot.path],
                includeFileNames: ["package-lock.json"],
                includeFileGlobs: [],
                excludeDirectoryNames: [],
                maxDepth: 1
            )

            let result = try discoverer.candidateFileResult()

            #expect(result.files.isEmpty)
            #expect(result.issues == [
                CollectorIssue(
                    path: fileRoot.path,
                    reason: HealthMessages.directoryEnumerationUnavailable
                )
            ])
        }
    }

    @Test
    func recordsUnreadableEntryIssueAndKeepsReadableFiles() async throws {
        try await Fixture.withTemporaryDirectory { root in
            let readable = root.appending(path: "readable/package-lock.json")
            let unreadable = root.appending(path: "unreadable/package-lock.json")
            try writeFile(readable)
            try writeFile(unreadable)

            let discoverer = ProjectFileDiscoverer(
                roots: [root.path],
                includeFileNames: ["package-lock.json"],
                includeFileGlobs: [],
                excludeDirectoryNames: [],
                maxDepth: 2,
                resourceValues: { url, keys in
                    if url.path.hasSuffix("/unreadable/package-lock.json") {
                        throw CocoaError(.fileReadUnknown)
                    }
                    return try url.resourceValues(forKeys: keys)
                }
            )

            let result = try discoverer.candidateFileResult()

            let parentDirectories = result.files.map { $0.deletingLastPathComponent().lastPathComponent }
            #expect(parentDirectories == ["readable"])
            #expect(result.issues.count == 1)
            #expect(result.issues.first?.path.hasSuffix("/unreadable/package-lock.json") == true)
            let reason = result.issues.first?.reason
            #expect(reason?.contains(HealthMessages.directoryEnumerationUnavailable) == true)
        }
    }

    @Test
    func stopsAtMatchedFileBudgetAndRecordsIssue() async throws {
        try await Fixture.withTemporaryDirectory { root in
            try writeFile(root.appending(path: "one/package-lock.json"))
            try writeFile(root.appending(path: "two/package-lock.json"))

            let discoverer = ProjectFileDiscoverer(
                roots: [root.path],
                includeFileNames: ["package-lock.json"],
                includeFileGlobs: [],
                excludeDirectoryNames: [],
                maxDepth: 2,
                budget: ProjectFileDiscoveryBudget(
                    maxDirectoriesVisited: 10,
                    maxFilesMatched: 1,
                    maxWallClockSeconds: ConfigurationDefaults.projectMaxWallClockSeconds
                )
            )

            let result = try discoverer.candidateFileResult()

            #expect(result.files.count == 1)
            #expect(result.issues.count == 1)
            #expect(result.issues.first?.reason == HealthMessages.projectDiscoveryLimitReached(
                maxDirectories: 10,
                maxFiles: 1
            ))
        }
    }

    @Test
    func stopsAtWallClockBudgetAndRecordsIssue() async throws {
        try await Fixture.withTemporaryDirectory { root in
            try writeFile(root.appending(path: "one/package-lock.json"))
            try writeFile(root.appending(path: "two/package-lock.json"))
            let clock = ProjectFileDiscoveryTestClock()

            let discoverer = ProjectFileDiscoverer(
                roots: [root.path],
                includeFileNames: ["package-lock.json"],
                includeFileGlobs: [],
                excludeDirectoryNames: [],
                maxDepth: 2,
                budget: ProjectFileDiscoveryBudget(
                    maxDirectoriesVisited: ConfigurationDefaults.projectMaxDirectoriesVisited,
                    maxFilesMatched: ConfigurationDefaults.projectMaxFilesMatched,
                    maxWallClockSeconds: 1
                ),
                now: clock.now
            )

            let result = try discoverer.candidateFileResult()

            #expect(result.issues.count == 1)
            #expect(result.issues.first?.reason == HealthMessages.directoryEnumerationTimeLimitReached(
                seconds: 1
            ))
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
