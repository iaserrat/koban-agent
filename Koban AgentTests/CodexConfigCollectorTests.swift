import Foundation
import Testing
@testable import Koban_Agent

// MARK: - CodexConfigCollectorTests

struct CodexConfigCollectorTests {
    @Test
    func collectsConfigProfilesAndMCPServers() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: ".codex/config.toml")
            try writeFile(
                configURL,
                contents: #"""
                model = "gpt-5"

                [mcp_servers.docs]
                command = "npx"
                args = ["-y", "docs-mcp"]

                [mcp_servers.gateway]
                url = "https://mcp.example.com"

                [hooks.before_run]
                command = "echo ok"
                """#
            )

            let collector = CodexConfigCollector(
                configURLs: [configURL],
                hooksURLs: [],
                rulesDirectories: [],
                skillsDirectories: []
            )

            let items = try await collector.snapshot()

            let profile = try #require(items.first { $0.kind == .configProfile })
            #expect(profile.name == "config.toml")

            let docs = try #require(items.first { $0.name == "docs" })
            #expect(docs.kind == .mcpServer)
            #expect(docs.provenance.origin == "npx")
            #expect(docs.provenance.detail == "npx -y docs-mcp")

            let gateway = try #require(items.first { $0.name == "gateway" })
            #expect(gateway.kind == .mcpServer)
            #expect(gateway.provenance.origin == "https://mcp.example.com")

            let hook = try #require(items.first { $0.name == "before_run" })
            #expect(hook.kind == .hook)
        }
    }

    @Test
    func collectsHooksRulesAndSkills() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let hooksURL = directory.appending(path: ".codex/hooks.json")
            try writeFile(hooksURL, contents: #"{"before_run": [{"command": "echo ok"}]}"#)
            let ruleURL = directory.appending(path: ".codex/rules/default.rules")
            try writeFile(ruleURL, contents: "allow")
            let skillURL = directory.appending(path: ".agents/skills/reviewer/SKILL.md")
            try writeFile(skillURL, contents: "# Reviewer")

            let collector = CodexConfigCollector(
                configURLs: [],
                hooksURLs: [hooksURL],
                rulesDirectories: [ruleURL.deletingLastPathComponent()],
                skillsDirectories: [directory.appending(path: ".agents/skills")]
            )

            let items = try await collector.snapshot()

            let hook = try #require(items.first { $0.kind == .hook })
            #expect(hook.name == "before_run")
            let rule = try #require(items.first { $0.kind == .rule })
            #expect(rule.name == "default.rules")
            let skill = try #require(items.first { $0.kind == .skill })
            #expect(skill.name == "reviewer")
        }
    }

    @Test
    func malformedConfigAndHooksReportVisibilityIssuesAndKeepOtherItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: ".codex/config.toml")
            try writeFile(configURL, contents: "[mcp_servers")
            let hooksURL = directory.appending(path: ".codex/hooks.json")
            try writeFile(hooksURL, contents: #"{"before_run": ["#)
            let ruleURL = directory.appending(path: ".codex/rules/default.rules")
            try writeFile(ruleURL, contents: "allow")
            let skillURL = directory.appending(path: ".agents/skills/reviewer/SKILL.md")
            try writeFile(skillURL, contents: "# Reviewer")

            let collector = CodexConfigCollector(
                configURLs: [configURL],
                hooksURLs: [hooksURL],
                rulesDirectories: [ruleURL.deletingLastPathComponent()],
                skillsDirectories: [directory.appending(path: ".agents/skills")]
            )

            let snapshot = try await collector.collect()

            let rule = try #require(snapshot.items.first { $0.kind == .rule })
            #expect(rule.name == "default.rules")
            let skill = try #require(snapshot.items.first { $0.kind == .skill })
            #expect(skill.name == "reviewer")
            #expect(snapshot.items.contains { $0.kind == .configProfile } == false)
            #expect(snapshot.items.contains { $0.kind == .hook } == false)
            #expect(snapshot.issues.map(\.path).sorted() == [configURL.path, hooksURL.path].sorted())
        }
    }

    @Test
    func oversizedConfigAndHooksReportVisibilityIssuesWithoutItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: ".codex/config.toml")
            let hooksURL = directory.appending(path: ".codex/hooks.json")
            try writeFile(configURL, contents: String(repeating: "a", count: 101))
            try writeFile(hooksURL, contents: String(repeating: "b", count: 101))

            let collector = CodexConfigCollector(
                configURLs: [configURL],
                hooksURLs: [hooksURL],
                rulesDirectories: [],
                skillsDirectories: [],
                fileValidator: AgentConfigFileValidator(maxBytes: 100)
            )

            let snapshot = try await collector.collect()

            #expect(snapshot.items.isEmpty)
            #expect(snapshot.issues.count == 2)
            #expect(Set(snapshot.issues.map(\.path)) == Set([configURL.path, hooksURL.path]))
            #expect(snapshot.issues.allSatisfy {
                $0.reason == HealthMessages.agentConfigFileTooLarge(bytes: 101, maxBytes: 100)
            })
        }
    }

    @Test
    func missingPathsYieldNoItems() async throws {
        let collector = CodexConfigCollector(
            configURLs: [URL(filePath: "/nonexistent/config.toml")],
            hooksURLs: [URL(filePath: "/nonexistent/hooks.json")],
            rulesDirectories: [URL(filePath: "/nonexistent/rules", directoryHint: .isDirectory)],
            skillsDirectories: [URL(filePath: "/nonexistent/skills", directoryHint: .isDirectory)]
        )

        let items = try await collector.snapshot()
        #expect(items.isEmpty)
    }
}

private func writeFile(_ url: URL, contents: String) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try Data(contents.utf8).write(to: url)
}
