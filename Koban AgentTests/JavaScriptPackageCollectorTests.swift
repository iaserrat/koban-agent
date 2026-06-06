import Foundation
import Testing
@testable import Koban_Agent

struct JavaScriptPackageCollectorTests {
    @Test
    func collectsPackagesFromAllV1JavaScriptLockfiles() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/package-lock.json"),
                contents: #"""
                {"packages": {"": {}, "node_modules/@scope/pkg": {"version": "1.2.3"}}}
                """#
            )
            try writeFile(
                directory.appending(path: "app/pnpm-lock.yaml"),
                contents: #"""
                packages:
                  /left-pad@1.3.0: {}
                """#
            )
            try writeFile(
                directory.appending(path: "app/yarn.lock"),
                contents: #"""
                "@types/node@npm:^20.0.0":
                  version "20.1.0"
                """#
            )
            try writeFile(
                directory.appending(path: "app/bun.lock"),
                contents: #"""
                {"packages": {"zod": ["zod@3.25.0", "", {}, ""]}}
                """#
            )

            let collector = JavaScriptPackageCollector(discoverer: discoverer(root: directory.path))
            let items = try await collector.snapshot()

            try expectItem(items, name: "@scope/pkg", version: "1.2.3", origin: "npm")
            try expectItem(items, name: "left-pad", version: "1.3.0", origin: "pnpm")
            try expectItem(items, name: "@types/node", version: "20.1.0", origin: "yarn")
            try expectItem(items, name: "zod", version: "3.25.0", origin: "bun")
        }
    }

    @Test
    func shrinkwrapShadowsPackageLockInSameDirectory() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/package-lock.json"),
                contents: #"{"packages": {"node_modules/package-lock-only": {"version": "1.0.0"}}}"#
            )
            try writeFile(
                directory.appending(path: "app/npm-shrinkwrap.json"),
                contents: #"{"packages": {"node_modules/shrinkwrap-only": {"version": "2.0.0"}}}"#
            )

            let collector = JavaScriptPackageCollector(discoverer: discoverer(root: directory.path))
            let items = try await collector.snapshot()

            #expect(items.contains { $0.name == "package-lock-only" } == false)
            try expectItem(items, name: "shrinkwrap-only", version: "2.0.0", origin: "npm")
        }
    }

    @Test
    func npmPackageDetailIncludesResolvedIntegrityAndScope() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/package-lock.json"),
                contents: #"""
                {
                  "packages": {
                    "node_modules/vite": {
                      "version": "5.0.0",
                      "resolved": "https://registry.npmjs.org/vite/-/vite-5.0.0.tgz",
                      "integrity": "sha512-test",
                      "dev": true
                    }
                  }
                }
                """#
            )

            let collector = JavaScriptPackageCollector(discoverer: discoverer(root: directory.path))
            let items = try await collector.snapshot()

            let item = try #require(items.first { $0.name == "vite" })
            #expect(item.provenance
                .detail ==
                "resolved=https://registry.npmjs.org/vite/-/vite-5.0.0.tgz integrity=sha512-test scope=dev")
        }
    }

    @Test
    func malformedLockfileRecordsIssueAndKeepsValidPackages() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let malformed = directory.appending(path: "bad/package-lock.json")
            try writeFile(malformed, contents: "{")
            try writeFile(
                directory.appending(path: "good/pnpm-lock.yaml"),
                contents: #"""
                packages:
                  /left-pad@1.3.0: {}
                """#
            )

            let collector = JavaScriptPackageCollector(discoverer: discoverer(root: directory.path))
            let snapshot = try await collector.collect()

            try expectItem(snapshot.items, name: "left-pad", version: "1.3.0", origin: "pnpm")
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.path.hasSuffix("/bad/package-lock.json") == true)
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

    private func expectItem(
        _ items: [InventoryItem],
        name: String,
        version: String,
        origin: String
    ) throws {
        let item = try #require(items.first { $0.name == name })
        #expect(item.version == version)
        #expect(item.provenance.origin == origin)
    }
}
