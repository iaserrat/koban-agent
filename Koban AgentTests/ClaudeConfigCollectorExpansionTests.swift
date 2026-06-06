import Foundation
import Testing
@testable import Koban_Agent

struct ClaudeConfigCollectorExpansionTests {
    @Test
    func collectsProjectMCPHooksPluginsSkillsAndInstructions() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let urls = try fixtureURLs(directory)
            let collector = ClaudeConfigCollector(
                configURLs: [urls.userConfigURL, urls.projectConfigURL],
                settingsURLs: [urls.settingsURL],
                customizationDirectories: [
                    ClaudeCustomizationDirectory(url: urls.commandDirectoryURL, kind: .command),
                    ClaudeCustomizationDirectory(url: urls.skillDirectoryURL, kind: .skill)
                ],
                instructionURLs: [urls.instructionURL]
            )

            let items = try await collector.snapshot()

            #expect(items.contains { $0.kind == .mcpServer && $0.name == "project-gateway" })
            #expect(items.contains { $0.kind == .hook && $0.name == "hooks" })
            #expect(items.contains { $0.kind == .plugin && $0.name == "formatter@team" })
            #expect(items.contains { $0.kind == .plugin && $0.name == "team" })
            #expect(items.contains { $0.kind == .command && $0.name == "fix.md" })
            #expect(items.contains { $0.kind == .skill && $0.name == "SKILL.md" })
            #expect(items.contains { $0.kind == .instruction && $0.name == "CLAUDE.md" })
        }
    }

    @Test
    func categoryFlagsSkipHooksAndPluginsFromSettings() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let urls = try fixtureURLs(directory)
            let collector = ClaudeConfigCollector(
                configURLs: [urls.userConfigURL],
                settingsURLs: [urls.settingsURL],
                includeHooks: false,
                includePlugins: false
            )

            let items = try await collector.snapshot()

            #expect(items.contains { $0.kind == .settings && $0.name == "hooks" })
            #expect(items.contains { $0.kind == .hook } == false)
            #expect(items.contains { $0.kind == .plugin } == false)
        }
    }

    private func fixtureURLs(_ directory: URL) throws -> ClaudeExpansionFixtureURLs {
        let urls = ClaudeExpansionFixtureURLs(directory: directory)
        try Data("{}".utf8).write(to: urls.userConfigURL)
        try writeFile(
            urls.projectConfigURL,
            contents: #"{"mcpServers": {"project-gateway": {"url": "https://project.example.com"}}}"#
        )
        try writeFile(urls.settingsURL, contents: settingsJSON)
        try writeFile(urls.commandDirectoryURL.appending(path: "fix.md"), contents: "# Fix")
        try writeFile(urls.skillDirectoryURL.appending(path: "SKILL.md"), contents: "# Audit")
        try writeFile(urls.instructionURL, contents: "# Project instructions")
        return urls
    }

    private var settingsJSON: String {
        #"""
        {
          "hooks": {"PreToolUse": []},
          "enabledPlugins": {"formatter@team": true},
          "extraKnownMarketplaces": [{"name": "team", "source": {"type": "github", "repo": "team/plugins"}}]
        }
        """#
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: url)
    }
}
