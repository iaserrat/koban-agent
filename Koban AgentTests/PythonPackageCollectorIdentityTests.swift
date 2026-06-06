import Foundation
import Testing
@testable import Koban_Agent

/// A pyproject can declare the same dependency in several sections. Those must collapse to one
/// inventory item, not several rows colliding on the same identity.
struct PythonPackageCollectorIdentityTests {
    @Test
    func sameDependencyAcrossSectionsCollapsesToOneItem() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try writeFile(
                directory.appending(path: "app/pyproject.toml"),
                contents: #"""
                [project]
                dependencies = ["django==4.0"]

                [project.optional-dependencies]
                dev = ["django==4.0"]

                [build-system]
                requires = ["django>=3.0"]
                """#
            )

            let collector = PythonPackageCollector(discoverer: discoverer(root: directory.path))
            let django = try await collector.snapshot().filter { $0.name == "django" }

            #expect(django.count == 1)
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
}
