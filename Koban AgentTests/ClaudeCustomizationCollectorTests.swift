import Foundation
import Testing
@testable import Koban_Agent

struct ClaudeCustomizationCollectorTests {
    @Test
    func badCustomizationFileReportsIssueAndKeepsOtherFiles() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            try Data("{}".utf8).write(to: configURL)
            let agentsURL = directory.appending(path: ".claude/agents")
            let validURL = agentsURL.appending(path: "reviewer.md")
            let brokenURL = agentsURL.appending(path: "broken.md")
            try writeFile(validURL, contents: "# Reviewer")
            try FileManager.default.createSymbolicLink(
                at: brokenURL,
                withDestinationURL: agentsURL.appending(path: "missing.md")
            )

            let collector = ClaudeConfigCollector(
                configURL: configURL,
                customizationDirectories: [
                    ClaudeCustomizationDirectory(url: agentsURL, kind: .agent)
                ]
            )

            let snapshot = try await collector.collect()

            let agent = try #require(snapshot.items.first { $0.kind == .agent })
            #expect(agent.name == "reviewer.md")
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.path.hasSuffix("/broken.md") == true)
        }
    }

    @Test
    func customizationDirectoryStopsAtEntryLimitAndReportsIssue() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            try Data("{}".utf8).write(to: configURL)
            let agentsURL = directory.appending(path: ".claude/agents")
            try writeFile(agentsURL.appending(path: "one.md"), contents: "# One")
            try writeFile(agentsURL.appending(path: "two.md"), contents: "# Two")

            let collector = ClaudeConfigCollector(
                configURL: configURL,
                customizationDirectories: [
                    ClaudeCustomizationDirectory(url: agentsURL, kind: .agent)
                ],
                customizationMaxEntries: 1
            )

            let snapshot = try await collector.collect()

            #expect(snapshot.items.count { $0.kind == .agent } == 1)
            #expect(snapshot.issues == [
                CollectorIssue(
                    path: agentsURL.path,
                    reason: HealthMessages.directoryEnumerationEntryLimitReached(maxEntries: 1)
                )
            ])
        }
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: url)
    }
}
