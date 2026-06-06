import Foundation
import Testing
@testable import Koban_Agent

struct OpenCodeConfigCollectorTests {
    @Test
    func collectsConfigMCPAndCustomizationFiles() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: ".config/opencode/opencode.jsonc")
            try writeFile(
                configURL,
                contents: #"""
                {
                  // OpenCode config
                  "mcp": {
                    "docs": {"command": "npx", "args": ["-y", "docs-mcp"]}
                  },
                  "plugin": ["opencode-plugin-example"]
                }
                """#
            )
            let agentURL = directory.appending(path: ".config/opencode/agent/reviewer.md")
            try writeFile(agentURL, contents: "# Reviewer")
            let commandURL = directory.appending(path: ".config/opencode/command/check.md")
            try writeFile(commandURL, contents: "# Check")
            let pluginURL = directory.appending(path: ".config/opencode/plugin/example.md")
            try writeFile(pluginURL, contents: "# Plugin")
            let instructionURL = directory.appending(path: ".config/opencode/AGENTS.md")
            try writeFile(instructionURL, contents: "# Instructions")

            let collector = OpenCodeConfigCollector(
                configURLs: [configURL],
                agentDirectories: [agentURL.deletingLastPathComponent()],
                commandDirectories: [commandURL.deletingLastPathComponent()],
                pluginDirectories: [pluginURL.deletingLastPathComponent()],
                instructionURLs: [instructionURL],
                includeMCP: true
            )

            let items = try await collector.snapshot()

            try expectItem(items, kind: .configProfile, name: "opencode.jsonc")
            try expectItem(items, kind: .mcpServer, name: "docs")
            try expectItem(items, kind: .agent, name: "reviewer.md")
            try expectItem(items, kind: .command, name: "check.md")
            try expectItem(items, kind: .plugin, name: "example.md")
            try expectItem(items, kind: .plugin, name: "opencode-plugin-example")
            try expectItem(items, kind: .instruction, name: "AGENTS.md")
        }
    }

    @Test
    func malformedConfigReportsVisibilityIssueAndKeepsConfigProfile() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: "opencode.json")
            try writeFile(configURL, contents: #"{"mcp": {"#)
            let collector = OpenCodeConfigCollector(
                configURLs: [configURL],
                agentDirectories: [],
                commandDirectories: [],
                pluginDirectories: [],
                instructionURLs: [],
                includeMCP: true
            )

            let snapshot = try await collector.collect()

            try expectItem(snapshot.items, kind: .configProfile, name: "opencode.json")
            #expect(snapshot.items.contains { $0.kind == .mcpServer } == false)
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.path == configURL.path)
        }
    }

    @Test
    func missingPathsYieldNoItems() async throws {
        let collector = OpenCodeConfigCollector(
            configURLs: [URL(filePath: "/nonexistent/opencode.json")],
            agentDirectories: [URL(filePath: "/nonexistent/agent", directoryHint: .isDirectory)],
            commandDirectories: [URL(filePath: "/nonexistent/command", directoryHint: .isDirectory)],
            pluginDirectories: [URL(filePath: "/nonexistent/plugin", directoryHint: .isDirectory)],
            instructionURLs: [URL(filePath: "/nonexistent/AGENTS.md")]
        )

        let items = try await collector.snapshot()
        #expect(items.isEmpty)
    }

    @Test
    func managedPreferencePlistCreatesConfigProfile() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let plistURL = directory.appending(path: "ai.opencode.managed.plist")
            try writeFile(
                plistURL,
                contents: #"""
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
                  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0"><dict><key>disabled_providers</key><array/></dict></plist>
                """#
            )

            let collector = OpenCodeConfigCollector(
                configURLs: [plistURL],
                agentDirectories: [],
                commandDirectories: [],
                pluginDirectories: [],
                instructionURLs: [],
                includeMCP: true
            )

            let items = try await collector.snapshot()
            try expectItem(items, kind: .configProfile, name: "ai.opencode.managed.plist")
        }
    }

    @Test
    func includeMCPFalseSkipsMCPEntriesButKeepsConfigProfile() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: "opencode.json")
            try writeFile(configURL, contents: #"{"mcp": {"docs": {"command": "npx"}}}"#)
            let collector = OpenCodeConfigCollector(
                configURLs: [configURL],
                agentDirectories: [],
                commandDirectories: [],
                pluginDirectories: [],
                instructionURLs: [],
                includeMCP: false
            )

            let items = try await collector.snapshot()
            try expectItem(items, kind: .configProfile, name: "opencode.json")
            #expect(items.contains { $0.kind == .mcpServer } == false)
        }
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: url)
    }

    private func expectItem(_ items: [InventoryItem], kind: InventoryKind, name: String) throws {
        let item = try #require(items.first { $0.kind == kind && $0.name == name })
        #expect(item.name == name)
    }
}
