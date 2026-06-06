import Foundation
import Testing
@testable import Koban_Agent

struct CursorConfigCollectorTests {
    @Test
    func collectsMCPServersAndRules() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let mcpURL = directory.appending(path: ".cursor/mcp.json")
            try writeFile(
                mcpURL,
                contents: #"""
                {
                  "mcpServers": {
                    "docs": {"command": "npx", "args": ["-y", "docs-mcp"]},
                    "gateway": {"url": "https://mcp.example.com"}
                  }
                }
                """#
            )
            let ruleURL = directory.appending(path: ".cursor/rules/frontend.mdc")
            try writeFile(ruleURL, contents: "Use the design system.")
            let legacyURL = directory.appending(path: ".cursorrules")
            try writeFile(legacyURL, contents: "Legacy project rule.")
            let instructionURL = directory.appending(path: "AGENTS.md")
            try writeFile(instructionURL, contents: "Project instructions.")

            let collector = CursorConfigCollector(
                mcpConfigURLs: [mcpURL],
                rulesDirectories: [ruleURL.deletingLastPathComponent()],
                legacyRuleURLs: [legacyURL],
                instructionURLs: [instructionURL]
            )

            let items = try await collector.snapshot()

            let docs = try #require(items.first { $0.name == "docs" })
            #expect(docs.kind == .mcpServer)
            #expect(docs.provenance.detail == "npx -y docs-mcp")
            let rule = try #require(items.first { $0.name == "frontend.mdc" })
            #expect(rule.kind == .rule)
            let legacyRule = try #require(items.first { $0.name == ".cursorrules" })
            #expect(legacyRule.kind == .rule)
            let instruction = try #require(items.first { $0.name == "AGENTS.md" })
            #expect(instruction.kind == .instruction)
        }
    }

    @Test
    func malformedMCPConfigReportsVisibilityIssueAndKeepsOtherItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let mcpURL = directory.appending(path: ".cursor/mcp.json")
            try writeFile(mcpURL, contents: #"{"mcpServers": {"#)
            let ruleURL = directory.appending(path: ".cursor/rules/frontend.mdc")
            try writeFile(ruleURL, contents: "Use the design system.")
            let collector = CursorConfigCollector(
                mcpConfigURLs: [mcpURL],
                rulesDirectories: [ruleURL.deletingLastPathComponent()],
                legacyRuleURLs: [],
                instructionURLs: []
            )

            let snapshot = try await collector.collect()

            let rule = try #require(snapshot.items.first { $0.name == "frontend.mdc" })
            #expect(rule.kind == .rule)
            #expect(snapshot.items.contains { $0.kind == .mcpServer } == false)
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.path == mcpURL.path)
        }
    }

    @Test
    func legacyRuleHashFailureReportsIssueAndKeepsItem() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let legacyURL = directory.appending(path: ".cursorrules")
            try FileManager.default.createDirectory(at: legacyURL, withIntermediateDirectories: true)

            let collector = CursorConfigCollector(
                mcpConfigURLs: [],
                rulesDirectories: [],
                legacyRuleURLs: [legacyURL],
                instructionURLs: []
            )

            let snapshot = try await collector.collect()

            let rule = try #require(snapshot.items.first)
            #expect(rule.name == ".cursorrules")
            #expect(rule.provenance.detail == nil)
            #expect(snapshot.issues.count == 1)
            let issue = try #require(snapshot.issues.first)
            #expect(issue.path == legacyURL.path)
            #expect(issue.reason.hasPrefix(HealthMessages.fileHashUnavailablePrefix))
        }
    }

    @Test
    func missingPathsYieldNoItems() async throws {
        let collector = CursorConfigCollector(
            mcpConfigURLs: [URL(filePath: "/nonexistent/mcp.json")],
            rulesDirectories: [URL(filePath: "/nonexistent/rules", directoryHint: .isDirectory)],
            legacyRuleURLs: [URL(filePath: "/nonexistent/.cursorrules")],
            instructionURLs: [URL(filePath: "/nonexistent/AGENTS.md")]
        )

        let items = try await collector.snapshot()
        #expect(items.isEmpty)
    }

    @Test
    func cancelledTaskStopsMCPConfigCollection() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let mcpURL = directory.appending(path: ".cursor/mcp.json")
            try writeFile(
                mcpURL,
                contents: #"{"mcpServers":{"docs":{"command":"npx"}}}"#
            )
            let collector = CursorConfigCollector(
                mcpConfigURLs: [mcpURL],
                rulesDirectories: [],
                legacyRuleURLs: [],
                instructionURLs: []
            )
            let task = Task {
                try await collector.collect()
            }
            task.cancel()

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
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
