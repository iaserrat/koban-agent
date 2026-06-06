import Foundation
import Testing
@testable import Koban_Agent

struct ClaudeConfigCollectorTests {
    @Test
    func collectsStdioAndRemoteServers() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            let json = #"""
            {
              "mcpServers": {
                "weather": {"command": "npx", "args": ["-y", "weather-mcp"]},
                "gateway": {"type": "http", "url": "https://mcp.example.com"}
              }
            }
            """#
            try Data(json.utf8).write(to: configURL)

            let collector = ClaudeConfigCollector(configURL: configURL)
            let items = try await collector.snapshot()

            #expect(items.count == 2)
            let weather = try #require(items.first { $0.name == "weather" })
            #expect(weather.kind == .mcpServer)
            #expect(weather.provenance.detail == "npx -y weather-mcp")
            let gateway = try #require(items.first { $0.name == "gateway" })
            #expect(gateway.provenance.detail == "https://mcp.example.com")
        }
    }

    @Test
    func collectsSettingsAndCustomizationFiles() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            try Data("{}".utf8).write(to: configURL)
            let settingsURL = directory.appending(path: ".claude/settings.json")
            try writeFile(
                settingsURL,
                contents: #"{"permissions": {"allow": ["Bash(ls)"], "deny": ["Bash(rm)"]}}"#
            )
            let agentURL = directory.appending(path: ".claude/agents/reviewer.md")
            try writeFile(agentURL, contents: "# Reviewer")

            let collector = ClaudeConfigCollector(
                configURL: configURL,
                settingsURLs: [settingsURL],
                customizationDirectories: [
                    ClaudeCustomizationDirectory(url: agentURL.deletingLastPathComponent(), kind: .agent)
                ]
            )

            let items = try await collector.snapshot()

            let settings = try #require(items.first { $0.kind == .settings })
            #expect(settings.name == "permissions")
            #expect(items.contains { $0.kind == .settings && $0.name == "permissions.allow" })
            #expect(items.contains { $0.kind == .settings && $0.name == "permissions.deny" })
            let agent = try #require(items.first { $0.kind == .agent })
            #expect(agent.name == "reviewer.md")
        }
    }

    @Test
    func doesNotPersistSecretBearingMCPFields() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            let json = #"""
            {
              "mcpServers": {
                "gateway": {
                  "type": "http",
                  "url": "https://mcp.example.com",
                  "headers": {"Authorization": "Bearer secret-token"},
                  "env": {"API_KEY": "secret-key"},
                  "oauth": {"clientSecret": "secret-oauth"},
                  "headersHelper": "security find-generic-password -s secret"
                }
              }
            }
            """#
            try Data(json.utf8).write(to: configURL)

            let collector = ClaudeConfigCollector(configURL: configURL)
            let items = try await collector.snapshot()
            let gateway = try #require(items.first { $0.name == "gateway" })

            #expect(gateway.provenance.origin == "https://mcp.example.com")
            #expect(gateway.provenance.detail == "https://mcp.example.com headersHelper")
            #expect(gateway.provenance.detail?.contains("secret") == false)
            #expect(gateway.provenance.detail?.contains("API_KEY") == false)
        }
    }

    @Test
    func settingsContentChangesProduceModifiedInventory() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            try Data("{}".utf8).write(to: configURL)
            let settingsURL = directory.appending(path: ".claude/settings.json")
            try writeFile(settingsURL, contents: #"{"permissions": {"allow": ["Bash(ls)"]}}"#)
            let collector = ClaudeConfigCollector(configURL: configURL, settingsURLs: [settingsURL])

            let previous = try await collector.snapshot()
            try writeFile(settingsURL, contents: #"{"permissions": {"allow": ["Bash(cat)"]}}"#)
            let current = try await collector.snapshot()

            let changes = InventoryDiffer.diff(previous: previous, current: current)
            #expect(changes.contains { $0.kind == .modified && $0.item.kind == .settings })
        }
    }

    @Test
    func malformedFilesReportVisibilityIssuesAndKeepOtherItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            try Data(#"{"mcpServers": {"#.utf8).write(to: configURL)
            let settingsURL = directory.appending(path: ".claude/settings.json")
            try writeFile(settingsURL, contents: #"{"permissions": "#)
            let pluginURL = directory.appending(path: ".claude/plugins.json")
            try writeFile(pluginURL, contents: #"{"plugins": ["#)
            let agentURL = directory.appending(path: ".claude/agents/reviewer.md")
            try writeFile(agentURL, contents: "# Reviewer")
            let instructionURL = directory.appending(path: "CLAUDE.md")
            try writeFile(instructionURL, contents: "# Project instructions")

            let collector = ClaudeConfigCollector(
                configURLs: [configURL],
                settingsURLs: [settingsURL],
                customizationDirectories: [
                    ClaudeCustomizationDirectory(url: agentURL.deletingLastPathComponent(), kind: .agent)
                ],
                instructionURLs: [instructionURL],
                pluginURLs: [pluginURL]
            )

            let snapshot = try await collector.collect()

            let agent = try #require(snapshot.items.first { $0.kind == .agent })
            #expect(agent.name == "reviewer.md")
            let instruction = try #require(snapshot.items.first { $0.kind == .instruction })
            #expect(instruction.name == "CLAUDE.md")
            #expect(snapshot.items.contains { $0.kind == .mcpServer } == false)
            #expect(snapshot.items.contains { $0.kind == .settings } == false)
            #expect(snapshot.items.contains { $0.kind == .plugin } == false)
            #expect(snapshot.issues.map(\.path).sorted() == [
                configURL.path,
                pluginURL.path,
                settingsURL.path
            ].sorted())
        }
    }

    @Test
    func missingFileYieldsNoItems() async throws {
        let collector = ClaudeConfigCollector(configURL: URL(filePath: "/nonexistent/.claude.json"))
        let items = try await collector.snapshot()
        #expect(items.isEmpty)
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: url)
    }
}
