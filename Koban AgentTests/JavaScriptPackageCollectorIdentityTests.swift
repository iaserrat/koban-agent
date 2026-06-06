import Foundation
import Testing
@testable import Koban_Agent

/// A dependency tree legitimately holds the same package at several versions at once, so each
/// (name, version) must stay a distinct inventory item. Collapsing them lets the differ report
/// phantom "modified" events on a stable system.
struct JavaScriptPackageCollectorIdentityTests {
    @Test
    func coexistingVersionsOfSamePackageAreDistinctItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/pnpm-lock.yaml"),
                contents: #"""
                packages:
                  /zod@3.25.76: {}
                  /zod@4.4.3: {}
                """#
            )

            let collector = JavaScriptPackageCollector(discoverer: discoverer(root: directory.path))
            let zod = try await collector.snapshot().filter { $0.name == "zod" }

            #expect(Set(zod.map(\.version)) == ["3.25.76", "4.4.3"])
            #expect(Set(zod.map(\.id)).count == 2)
        }
    }

    private func discoverer(root: String) -> ProjectFileDiscoverer {
        ProjectFileDiscoverer(
            roots: [root],
            includeFileNames: PackageMetadataNames.javascriptLockfiles,
            includeFileGlobs: [],
            excludeDirectoryNames: [],
            maxDepth: 3
        )
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: url)
    }
}
