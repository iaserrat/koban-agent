import Foundation
import Testing
@testable import Koban_Agent

struct CollectorFactoryProfileConfigIssueTests {
    @Test
    func codexProfileGlobInvalidDirectoryReportsIssue() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let codexDirectory = directory.appending(path: KnownPaths.codexDirectoryComponent)
            try Data("not a directory".utf8).write(to: codexDirectory)
            var config = DefaultConfiguration.value
            config.homebrew.enabled = false
            config.claude.enabled = false
            config.cursor.enabled = false
            config.opencode.enabled = false
            config.pi.enabled = false
            config.javascript.enabled = false
            config.python.enabled = false
            config.codex = CodexSettings(
                enabled: true,
                userConfigPath: codexDirectory.appending(path: KnownPaths.codexConfigName).path,
                profileConfigGlob: codexDirectory
                    .appending(path: "*.config.toml")
                    .path,
                projectRoots: [],
                includeSystemConfig: false,
                includeSkills: false,
                includeHooks: false,
                includeRules: false
            )

            let collectors = try CollectorFactory.make(for: config)
            let collector = try #require(collectors.first as? CodexConfigCollector)
            let snapshot = try await collector.collect()

            #expect(snapshot.items.isEmpty)
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.path == codexDirectory.path)
            #expect(snapshot.issues.first?.reason == HealthMessages.directoryEnumerationUnavailable)
        }
    }
}
