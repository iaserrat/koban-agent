import Foundation
import Testing
@testable import Koban_Agent

struct PiConfigCollectorTests {
    @Test
    func collectsMCPServersImportsSettingsAndPackages() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let mcpURL = directory.appending(path: ".pi/agent/mcp.json")
            try writeFile(
                mcpURL,
                contents: #"""
                {
                  "imports": ["cursor", "codex"],
                  "mcpServers": {
                    "docs": {"command": "npx", "args": ["-y", "docs-mcp"]}
                  }
                }
                """#
            )
            let settingsURL = directory.appending(path: ".pi/agent/settings.json")
            try writeFile(settingsURL, contents: #"{"autoAuth": true}"#)
            let packageURL = directory.appending(path: ".pi/agent/extensions/example/package.json")
            try writeFile(packageURL, contents: #"{"name": "example"}"#)

            let collector = PiConfigCollector(
                mcpConfigURLs: [mcpURL],
                settingsURLs: [settingsURL],
                packageDirectories: [directory.appending(path: ".pi/agent/extensions")],
                includeImports: true
            )

            let items = try await collector.snapshot()

            try expectItem(items, kind: .mcpServer, name: "docs")
            try expectItem(items, kind: .import, name: "cursor")
            try expectItem(items, kind: .settings, name: "autoAuth")
            try expectItem(items, kind: .plugin, name: "example")
        }
    }

    @Test
    func malformedMCPAndSettingsReportVisibilityIssuesAndKeepPackages() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let mcpURL = directory.appending(path: ".pi/agent/mcp.json")
            try writeFile(mcpURL, contents: #"{"mcpServers": {"#)
            let settingsURL = directory.appending(path: ".pi/agent/settings.json")
            try writeFile(settingsURL, contents: #"{"autoAuth": "#)
            let packageURL = directory.appending(path: ".pi/agent/extensions/example/package.json")
            try writeFile(packageURL, contents: #"{"name": "example"}"#)

            let collector = PiConfigCollector(
                mcpConfigURLs: [mcpURL],
                settingsURLs: [settingsURL],
                packageDirectories: [directory.appending(path: ".pi/agent/extensions")],
                includeImports: true
            )

            let snapshot = try await collector.collect()

            try expectItem(snapshot.items, kind: .plugin, name: "example")
            #expect(snapshot.items.contains { $0.kind == .mcpServer } == false)
            #expect(snapshot.items.contains { $0.kind == .settings } == false)
            #expect(snapshot.issues.map(\.path).sorted() == [mcpURL.path, settingsURL.path].sorted())
        }
    }

    @Test
    func missingPathsYieldNoItems() async throws {
        let collector = PiConfigCollector(
            mcpConfigURLs: [URL(filePath: "/nonexistent/mcp.json")],
            settingsURLs: [URL(filePath: "/nonexistent/settings.json")],
            packageDirectories: [URL(filePath: "/nonexistent/extensions", directoryHint: .isDirectory)],
            includeImports: true
        )

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

    private func expectItem(_ items: [InventoryItem], kind: InventoryKind, name: String) throws {
        let item = try #require(items.first { $0.kind == kind && $0.name == name })
        #expect(item.name == name)
    }
}
