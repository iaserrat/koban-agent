import Foundation
import Testing
@testable import Koban_Agent

struct JavaScriptPackageCollectorSizeTests {
    @Test
    func oversizedLockfileRecordsIssueAndKeepsValidPackages() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let maxBytes = 100
            let oversizedBytes = maxBytes + 1
            try writeFile(
                directory.appending(path: "large/package-lock.json"),
                contents: String(repeating: " ", count: oversizedBytes)
            )
            try writeFile(
                directory.appending(path: "good/pnpm-lock.yaml"),
                contents: #"""
                packages:
                  /left-pad@1.3.0: {}
                """#
            )

            let collector = JavaScriptPackageCollector(
                discoverer: discoverer(root: directory.path),
                fileValidator: PackageMetadataFileValidator(maxBytes: maxBytes)
            )
            let snapshot = try await collector.collect()

            try expectItem(snapshot.items, name: "left-pad", version: "1.3.0", origin: "pnpm")
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.reason == HealthMessages.packageMetadataFileTooLarge(
                bytes: oversizedBytes,
                maxBytes: maxBytes
            ))
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
