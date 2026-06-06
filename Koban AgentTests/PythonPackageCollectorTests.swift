import Foundation
import Testing
@testable import Koban_Agent

struct PythonPackageCollectorTests {
    @Test
    func collectsPythonDeclaredAndResolvedPackages() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/uv.lock"),
                contents: #"""
                [[package]]
                name = "fastapi"
                version = "0.115.0"
                """#
            )
            try writeFile(
                directory.appending(path: "app/pyproject.toml"),
                contents: #"""
                [project]
                dependencies = ["requests>=2"]
                """#
            )
            try writeFile(directory.appending(path: "app/requirements.txt"), contents: "django==5.0")
            try writeFile(directory.appending(path: "app/constraints.txt"), contents: "urllib3<3")

            let collector = PythonPackageCollector(discoverer: discoverer(root: directory.path))
            let items = try await collector.snapshot()

            try expectItem(items, name: "fastapi", kind: .pythonResolvedPackage, origin: "uv")
            try expectItem(items, name: "requests", kind: .pythonDeclaredRequirement, origin: "pyproject")
            try expectItem(items, name: "django", kind: .pythonDeclaredRequirement, origin: "pip")
            try expectItem(items, name: "urllib3", kind: .pythonConstraint, origin: "pip")
        }
    }

    @Test
    func collectsPyProjectOptionalBuildAndDependencyGroups() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/pyproject.toml"),
                contents: #"""
                [project]
                dependencies = ["requests>=2"]

                [project.optional-dependencies]
                dev = ["pytest>=8"]

                [build-system]
                requires = ["setuptools>=70"]

                [dependency-groups]
                docs = ["mkdocs>=1"]
                """#
            )

            let collector = PythonPackageCollector(discoverer: discoverer(root: directory.path))
            let items = try await collector.snapshot()

            try expectItem(items, name: "requests", kind: .pythonDeclaredRequirement, origin: "pyproject")
            try expectItem(items, name: "pytest", kind: .pythonDeclaredRequirement, origin: "pyproject")
            try expectItem(items, name: "setuptools", kind: .pythonDeclaredRequirement, origin: "pyproject")
            try expectItem(items, name: "mkdocs", kind: .pythonDeclaredRequirement, origin: "pyproject")
        }
    }

    @Test
    func collectsBoundedRequirementIncludesAndConstraints() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/requirements.txt"),
                contents: """
                flask==3.0 \\
                    --hash=sha256:abc
                -r requirements-dev.txt
                -c constraints.txt
                """
            )
            try writeFile(directory.appending(path: "app/requirements-dev.txt"), contents: "pytest>=8")
            try writeFile(directory.appending(path: "app/constraints.txt"), contents: "urllib3<3")

            let collector = PythonPackageCollector(discoverer: discoverer(root: directory.path))
            let items = try await collector.snapshot()

            try expectItem(items, name: "flask", kind: .pythonDeclaredRequirement, origin: "pip")
            try expectItem(items, name: "pytest", kind: .pythonDeclaredRequirement, origin: "pip")
            try expectItem(items, name: "urllib3", kind: .pythonConstraint, origin: "pip")
        }
    }

    @Test
    func malformedMetadataRecordsIssueAndKeepsValidPackages() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let malformed = directory.appending(path: "bad/pyproject.toml")
            try writeFile(malformed, contents: "[project")
            try writeFile(directory.appending(path: "good/requirements.txt"), contents: "django==5.0")

            let collector = PythonPackageCollector(discoverer: discoverer(root: directory.path))
            let snapshot = try await collector.collect()

            try expectItem(snapshot.items, name: "django", kind: .pythonDeclaredRequirement, origin: "pip")
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.path.hasSuffix("/bad/pyproject.toml") == true)
        }
    }

    @Test
    func oversizedMetadataRecordsIssueAndKeepsValidPackages() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let maxBytes = 100
            let oversizedBytes = maxBytes + 1
            let oversized = directory.appending(path: "large/pyproject.toml")
            try writeFile(oversized, contents: String(repeating: " ", count: oversizedBytes))
            try writeFile(directory.appending(path: "good/requirements.txt"), contents: "django==5.0")

            let collector = PythonPackageCollector(
                discoverer: discoverer(root: directory.path),
                fileValidator: PackageMetadataFileValidator(maxBytes: maxBytes)
            )
            let snapshot = try await collector.collect()

            try expectItem(snapshot.items, name: "django", kind: .pythonDeclaredRequirement, origin: "pip")
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
            includeFileNames: [
                PackageMetadataNames.uvLockName,
                PackageMetadataNames.pyprojectName,
                PackageMetadataNames.pylockName
            ],
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

    private func expectItem(
        _ items: [InventoryItem],
        name: String,
        kind: InventoryKind,
        origin: String
    ) throws {
        let item = try #require(items.first { $0.name == name })
        #expect(item.kind == kind)
        #expect(item.provenance.origin == origin)
    }
}
