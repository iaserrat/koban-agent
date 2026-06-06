import Foundation
import Testing
@testable import Koban_Agent

struct AgentConfigCollectorFileSizeTests {
    @Test
    func claudeOversizedParsedFilesReportIssuesWithoutFullReads() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            let settingsURL = directory.appending(path: ".claude/settings.json")
            let pluginURL = directory.appending(path: ".claude/plugins.json")
            try writeOversizedFile(configURL)
            try writeOversizedFile(settingsURL)
            try writeOversizedFile(pluginURL)

            let collector = ClaudeConfigCollector(
                configURLs: [configURL],
                settingsURLs: [settingsURL],
                pluginURLs: [pluginURL],
                fileValidator: validator
            )

            let snapshot = try await collector.collect()

            #expect(snapshot.items.isEmpty)
            #expect(snapshot.issues.map(\.path).sorted() == [
                configURL.path,
                pluginURL.path,
                settingsURL.path
            ].sorted())
            #expect(snapshot.issues.allSatisfy { $0.reason == oversizedReason })
        }
    }

    @Test
    func cursorOversizedMCPConfigReportsIssueAndKeepsRuleItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let mcpURL = directory.appending(path: ".cursor/mcp.json")
            let ruleURL = directory.appending(path: ".cursor/rules/style.mdc")
            try writeOversizedFile(mcpURL)
            try writeFile(ruleURL, contents: "Use the design system.")

            let collector = CursorConfigCollector(
                mcpConfigURLs: [mcpURL],
                rulesDirectories: [ruleURL.deletingLastPathComponent()],
                legacyRuleURLs: [],
                instructionURLs: [],
                fileValidator: validator
            )

            let snapshot = try await collector.collect()

            #expect(snapshot.items.contains { $0.kind == .rule && $0.name == "style.mdc" })
            #expect(snapshot.items.contains { $0.kind == .mcpServer } == false)
            #expect(snapshot.issues.map(\.path) == [mcpURL.path])
            #expect(snapshot.issues.first?.reason == oversizedReason)
        }
    }

    @Test
    func openCodeOversizedConfigReportsIssueAndSkipsDerivedItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: ".config/opencode/opencode.jsonc")
            try writeOversizedFile(configURL)

            let collector = OpenCodeConfigCollector(
                configURLs: [configURL],
                agentDirectories: [],
                commandDirectories: [],
                pluginDirectories: [],
                instructionURLs: [],
                includeMCP: true,
                fileValidator: validator
            )

            let snapshot = try await collector.collect()

            #expect(snapshot.items.contains {
                $0.kind == .configProfile && $0.name == "opencode.jsonc"
            })
            #expect(snapshot.items.contains { $0.kind == .mcpServer } == false)
            #expect(snapshot.items.contains { $0.kind == .plugin } == false)
            #expect(snapshot.issues.map(\.path) == [configURL.path])
            #expect(snapshot.issues.first?.reason == oversizedReason)
        }
    }

    @Test
    func piOversizedParsedFilesReportIssuesAndKeepPackageItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let mcpURL = directory.appending(path: ".config/pi/mcp.json")
            let settingsURL = directory.appending(path: ".config/pi/settings.json")
            let packageURL = directory.appending(path: ".config/pi/packages/example/package.json")
            try writeOversizedFile(mcpURL)
            try writeOversizedFile(settingsURL)
            try writeFile(packageURL, contents: #"{"name": "example"}"#)

            let collector = PiConfigCollector(
                mcpConfigURLs: [mcpURL],
                settingsURLs: [settingsURL],
                packageDirectories: [
                    packageURL.deletingLastPathComponent().deletingLastPathComponent()
                ],
                includeImports: true,
                fileValidator: validator
            )

            let snapshot = try await collector.collect()

            #expect(snapshot.items.contains { $0.kind == .plugin && $0.name == "example" })
            #expect(snapshot.items.contains { $0.kind == .mcpServer } == false)
            #expect(snapshot.items.contains { $0.kind == .settings } == false)
            #expect(snapshot.items.contains { $0.kind == .import } == false)
            #expect(snapshot.issues.map(\.path).sorted() == [
                mcpURL.path,
                settingsURL.path
            ].sorted())
            #expect(snapshot.issues.allSatisfy { $0.reason == oversizedReason })
        }
    }

    private var validator: AgentConfigFileValidator {
        AgentConfigFileValidator(maxBytes: 100)
    }

    private var oversizedReason: String {
        HealthMessages.agentConfigFileTooLarge(bytes: 101, maxBytes: 100)
    }

    private func writeOversizedFile(_ url: URL) throws {
        try writeFile(url, contents: String(repeating: "x", count: 101))
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: url)
    }
}
