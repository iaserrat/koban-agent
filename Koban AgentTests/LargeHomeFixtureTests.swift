import Foundation
import Testing
@testable import Koban_Agent

// MARK: - LargeHomeFixtureTests

/// End-to-end gate over a large, adverse home-directory tree. It builds real files on disk
/// (many projects, deep nesting, excluded directories, oversized and malformed metadata) and
/// runs the package collectors against them, proving the collectors stay within their
/// configured budgets and turn adverse inputs into recorded issues rather than crashes or
/// runaway work. Unreadability is injected through the discoverer's resource seam so the gate
/// stays deterministic regardless of the uid running the suite.
struct LargeHomeFixtureTests {
    private static let projectCount = 40
    private static let fileBudget = 10
    private static let directoryBudget = 10000
    private static let maxDepth = 3
    private static let maxWallClockSeconds = 30
    private static let limitReason = HealthMessages.projectDiscoveryLimitReached(
        maxDirectories: directoryBudget,
        maxFiles: fileBudget
    )

    @Test
    func collectorStaysWithinFileBudgetAcrossManyProjects() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            for index in 0 ..< Self.projectCount {
                try writeFile(
                    directory.appending(path: "proj-\(index)/package-lock.json"),
                    contents: packageLock(named: "pkg-\(index)")
                )
            }

            let snapshot = try await JavaScriptPackageCollector(
                discoverer: discoverer(root: directory.path, maxFilesMatched: Self.fileBudget)
            ).collect()

            // Discovery stops at the file budget and records why; the collector parses only
            // what discovery returned, so item count never exceeds the budget.
            #expect(snapshot.items.count == Self.fileBudget)
            #expect(snapshot.issues.contains { $0.reason == Self.limitReason })
        }
    }

    @Test
    func oversizedAndMalformedMetadataBecomeIssuesNotItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "valid/package-lock.json"),
                contents: packageLock(named: "good")
            )
            try writeFile(
                directory.appending(path: "oversized/yarn.lock"),
                contents: String(repeating: "# padding comment line\n", count: 200)
            )
            try writeFile(
                directory.appending(path: "malformed/package-lock.json"),
                contents: "{ this is not valid json"
            )

            let snapshot = try await JavaScriptPackageCollector(
                discoverer: discoverer(root: directory.path, maxFilesMatched: 100),
                fileValidator: PackageMetadataFileValidator(maxBytes: 1024)
            ).collect()

            #expect(snapshot.items.map(\.name) == ["good"])
            #expect(snapshot.issues.contains { $0.path.contains("/oversized/") })
            #expect(snapshot.issues.contains { $0.path.contains("/malformed/") })
        }
    }

    @Test
    func deepTreesAndExcludedDirectoriesAreNotTraversed() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/package-lock.json"),
                contents: packageLock(named: "within-depth")
            )
            try writeFile(
                directory.appending(path: "a/b/c/d/package-lock.json"),
                contents: packageLock(named: "too-deep")
            )
            try writeFile(
                directory.appending(path: "node_modules/package-lock.json"),
                contents: packageLock(named: "excluded")
            )

            let snapshot = try await JavaScriptPackageCollector(
                discoverer: discoverer(
                    root: directory.path,
                    maxFilesMatched: 100,
                    excludeDirectoryNames: ["node_modules"]
                )
            ).collect()

            #expect(snapshot.items.map(\.name) == ["within-depth"])
        }
    }

    @Test
    func unreadableDirectoryRecordsIssueAndCollectionContinues() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "readable/package-lock.json"),
                contents: packageLock(named: "readable")
            )
            try writeFile(
                directory.appending(path: "locked/package-lock.json"),
                contents: packageLock(named: "hidden")
            )

            let snapshot = try await JavaScriptPackageCollector(
                discoverer: discoverer(
                    root: directory.path,
                    maxFilesMatched: 100,
                    resourceValues: { url, keys in
                        if url.path.contains("/locked") {
                            throw CocoaError(.fileReadNoPermission)
                        }
                        return try url.resourceValues(forKeys: keys)
                    }
                )
            ).collect()

            #expect(snapshot.items.map(\.name) == ["readable"])
            #expect(snapshot.issues.contains { $0.path.contains("/locked") })
        }
    }

    @Test
    func pythonCollectorStaysWithinFileBudgetOverLargeTree() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            for index in 0 ..< Self.projectCount {
                try writeFile(
                    directory.appending(path: "svc-\(index)/requirements.txt"),
                    contents: "requests==2.31.0\n"
                )
            }

            let snapshot = try await PythonPackageCollector(
                discoverer: discoverer(
                    root: directory.path,
                    includeFileNames: [],
                    includeFileGlobs: PackageMetadataNames.pythonRequirementGlobs,
                    maxFilesMatched: Self.fileBudget
                )
            ).collect()

            #expect(snapshot.items.count <= Self.fileBudget)
            #expect(snapshot.issues.contains { $0.reason == Self.limitReason })
        }
    }
}

// MARK: - Helpers

extension LargeHomeFixtureTests {
    private func discoverer(
        root: String,
        includeFileNames: [String] = PackageMetadataNames.javascriptLockfiles,
        includeFileGlobs: [String] = [],
        maxFilesMatched: Int,
        excludeDirectoryNames: [String] = [],
        resourceValues: (@Sendable (URL, Set<URLResourceKey>) throws -> URLResourceValues)? = nil
    ) -> ProjectFileDiscoverer {
        ProjectFileDiscoverer(
            roots: [root],
            includeFileNames: includeFileNames,
            includeFileGlobs: includeFileGlobs,
            excludeDirectoryNames: excludeDirectoryNames,
            maxDepth: Self.maxDepth,
            budget: ProjectFileDiscoveryBudget(
                maxDirectoriesVisited: Self.directoryBudget,
                maxFilesMatched: maxFilesMatched,
                maxWallClockSeconds: Self.maxWallClockSeconds
            ),
            resourceValues: resourceValues ?? { try $0.resourceValues(forKeys: $1) }
        )
    }

    private func packageLock(named name: String) -> String {
        #"{"packages": {"node_modules/\#(name)": {"version": "1.0.0"}}}"#
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: url)
    }
}
