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

    @Test
    func nestedSkillIsDetectedByDirectoryName() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            try Data("{}".utf8).write(to: configURL)
            let skillsURL = directory.appending(path: ".claude/skills")
            try writeFile(skillsURL.appending(path: "sus-skill/SKILL.md"), contents: "# Sus")

            let collector = ClaudeConfigCollector(
                configURL: configURL,
                customizationDirectories: [
                    ClaudeCustomizationDirectory(url: skillsURL, kind: .skill)
                ]
            )

            let snapshot = try await collector.collect()

            let skill = try #require(snapshot.items.first { $0.kind == .skill })
            #expect(skill.name == "sus-skill")
            #expect(skill.path.hasSuffix("/sus-skill/SKILL.md"))
        }
    }

    @Test
    func subagentNestedInSubfolderIsDetected() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            try Data("{}".utf8).write(to: configURL)
            let agentsURL = directory.appending(path: ".claude/agents")
            try writeFile(agentsURL.appending(path: "review/reviewer.md"), contents: "# Reviewer")

            let collector = ClaudeConfigCollector(
                configURL: configURL,
                customizationDirectories: [
                    ClaudeCustomizationDirectory(url: agentsURL, kind: .agent)
                ]
            )

            let snapshot = try await collector.collect()

            let agent = try #require(snapshot.items.first { $0.kind == .agent })
            #expect(agent.name == "reviewer.md")
            #expect(agent.path.hasSuffix("/review/reviewer.md"))
        }
    }

    @Test
    func commandNestedInSubfolderIsIgnored() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            try Data("{}".utf8).write(to: configURL)
            let commandsURL = directory.appending(path: ".claude/commands")
            try writeFile(commandsURL.appending(path: "deploy.md"), contents: "# Deploy")
            try writeFile(commandsURL.appending(path: "frontend/component.md"), contents: "# Component")

            let collector = ClaudeConfigCollector(
                configURL: configURL,
                customizationDirectories: [
                    ClaudeCustomizationDirectory(url: commandsURL, kind: .command)
                ]
            )

            let snapshot = try await collector.collect()

            // Claude Code maps commands by filename only and does not namespace by subfolder,
            // so a nested file is not a separate command.
            #expect(snapshot.items.contains { $0.kind == .command && $0.name == "deploy.md" })
            #expect(snapshot.items.contains { $0.kind == .command && $0.name == "component.md" } == false)
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
