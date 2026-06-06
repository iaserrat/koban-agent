import Foundation
import Testing
@testable import Koban_Agent

struct PythonRequirementIncludeSizeTests {
    @Test
    func oversizedRequirementIncludeRecordsIssueAndKeepsReadableRequirements() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let maxBytes = 100
            let oversizedBytes = maxBytes + 1
            let oversized = directory.appending(path: "app/large-requirements.txt")
            try writeFile(
                directory.appending(path: "app/requirements.txt"),
                contents: """
                django==5.0
                -r large-requirements.txt
                flask==3.0
                """
            )
            try writeFile(oversized, contents: String(repeating: " ", count: oversizedBytes))

            let collector = PythonPackageCollector(
                discoverer: discoverer(root: directory.path),
                fileValidator: PackageMetadataFileValidator(maxBytes: maxBytes)
            )
            let snapshot = try await collector.collect()

            try expectItem(snapshot.items, name: "django")
            try expectItem(snapshot.items, name: "flask")
            #expect(snapshot.issues == [
                CollectorIssue(
                    path: oversized.path,
                    reason: HealthMessages.packageMetadataFileTooLarge(
                        bytes: oversizedBytes,
                        maxBytes: maxBytes
                    )
                )
            ])
        }
    }

    @Test
    func requirementIncludeFileBudgetStopsTraversalAndKeepsReadableRequirements() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/requirements.txt"),
                contents: """
                django==5.0
                -r one.txt
                -r two.txt
                flask==3.0
                """
            )
            try writeFile(directory.appending(path: "app/one.txt"), contents: "pytest>=8")
            try writeFile(directory.appending(path: "app/two.txt"), contents: "ruff>=0.8")

            let budget = PythonRequirementParseBudget(maxIncludedFiles: 1, maxIncludeDepth: 4)
            let collector = PythonPackageCollector(
                discoverer: discoverer(root: directory.path),
                requirementParseBudget: budget
            )
            let snapshot = try await collector.collect()

            try expectItem(snapshot.items, name: "django")
            try expectItem(snapshot.items, name: "pytest")
            try expectItem(snapshot.items, name: "flask")
            #expect(snapshot.items.contains { $0.name == "ruff" } == false)
            #expect(snapshot.issues == [
                includeLimitIssue(
                    path: directory.appending(path: "app/two.txt").path,
                    budget: budget
                )
            ])
        }
    }

    @Test
    func requirementIncludeDepthBudgetStopsTraversalAndKeepsReadableRequirements() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/requirements.txt"),
                contents: """
                django==5.0
                -r nested/one.txt
                flask==3.0
                """
            )
            try writeFile(directory.appending(path: "app/nested/one.txt"), contents: "-r two.txt")
            try writeFile(directory.appending(path: "app/nested/two.txt"), contents: "ruff>=0.8")

            let budget = PythonRequirementParseBudget(maxIncludedFiles: 10, maxIncludeDepth: 1)
            let collector = PythonPackageCollector(
                discoverer: discoverer(root: directory.path),
                requirementParseBudget: budget
            )
            let snapshot = try await collector.collect()

            try expectItem(snapshot.items, name: "django")
            try expectItem(snapshot.items, name: "flask")
            #expect(snapshot.items.contains { $0.name == "ruff" } == false)
            #expect(snapshot.issues == [
                includeLimitIssue(
                    path: directory.appending(path: "app/nested/two.txt").path,
                    budget: budget
                )
            ])
        }
    }

    private func discoverer(root: String) -> ProjectFileDiscoverer {
        ProjectFileDiscoverer(
            roots: [root],
            includeFileNames: [],
            includeFileGlobs: PackageMetadataNames.pythonRequirementGlobs,
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

    private func expectItem(_ items: [InventoryItem], name: String) throws {
        let item = try #require(items.first { $0.name == name })
        #expect(item.kind == .pythonDeclaredRequirement)
        #expect(item.provenance.origin == PackageMetadataNames.pipManager)
    }

    private func includeLimitIssue(path: String, budget: PythonRequirementParseBudget) -> CollectorIssue {
        CollectorIssue(
            path: path,
            reason: HealthMessages.pythonRequirementIncludeLimitReached(
                maxFiles: budget.maxIncludedFiles,
                maxDepth: budget.maxIncludeDepth
            )
        )
    }
}
