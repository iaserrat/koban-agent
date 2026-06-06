import Foundation
import Testing
@testable import Koban_Agent

// MARK: - ConfigurationSeederTests

struct ConfigurationSeederTests {
    @Test
    func copiesBundledDefaultToMissingUserConfig() async throws {
        try await Fixture.withTemporaryDirectory { root in
            let source = root.appending(path: "koban.default.yaml")
            let destination = root.appending(path: "config/koban.yaml")
            let contents = Data("watch:\n  debounceMilliseconds: 100\n".utf8)
            try contents.write(to: source)

            let seeded = try ConfigurationSeeder.seedIfNeeded(
                destination: destination,
                source: source
            )

            #expect(seeded)
            #expect(try Data(contentsOf: destination) == contents)
        }
    }

    @Test
    func leavesExistingUserConfigUntouched() async throws {
        try await Fixture.withTemporaryDirectory { root in
            let source = root.appending(path: "koban.default.yaml")
            let destination = root.appending(path: "config/koban.yaml")
            let existing = Data("watch:\n  debounceMilliseconds: 500\n".utf8)
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data("watch:\n  debounceMilliseconds: 100\n".utf8).write(to: source)
            try existing.write(to: destination)

            let seeded = try ConfigurationSeeder.seedIfNeeded(
                destination: destination,
                source: source
            )

            #expect(seeded == false)
            #expect(try Data(contentsOf: destination) == existing)
        }
    }

    @Test
    func propagatesBundledDefaultReadFailures() async throws {
        try await Fixture.withTemporaryDirectory { root in
            let destination = root.appending(path: "config/koban.yaml")
            let unreadableSource = root.appending(path: "not-a-file")
            try FileManager.default.createDirectory(
                at: unreadableSource,
                withIntermediateDirectories: true
            )

            #expect(throws: (any Error).self) {
                try ConfigurationSeeder.seedIfNeeded(
                    destination: destination,
                    source: unreadableSource
                )
            }
            #expect(FileManager.default.fileExists(atPath: destination.path) == false)
        }
    }
}
