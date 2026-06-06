import Foundation
import Testing
@testable import Koban_Agent

// MARK: - CollectorFactoryConfigurationTests

struct CollectorFactoryConfigurationTests {
    @Test
    func honorsOptInSystemManagedAndProfilePaths() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let profileURL = directory.appending(path: ".codex/review.config.toml")
            try FileManager.default.createDirectory(
                at: profileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data("model = \"gpt-5\"".utf8).write(to: profileURL)

            let config = optInPathConfiguration(codexDirectory: directory)
            let watchPaths = try normalizedPaths(CollectorFactory.make(for: config).flatMap(\.watchPaths))

            #expect(watchPaths.contains(normalizedPath(profileURL)))
            #expect(watchPaths.contains(normalizedPath(KnownPaths.codexSystemConfig())))
            #expect(watchPaths.contains(normalizedPath(KnownPaths.codexSystemHooks())))
            #expect(watchPaths.contains(normalizedPath(KnownPaths.codexSystemRulesDirectory())))
            #expect(watchPaths.contains(normalizedPath(KnownPaths.codexSystemSkillsDirectory())))
            #expect(watchPaths.contains(normalizedPath(KnownPaths.openCodeSystemManagedPreference())))
            #expect(watchPaths.contains(normalizedPath(KnownPaths.openCodeUserManagedPreference())))
        }
    }
}
