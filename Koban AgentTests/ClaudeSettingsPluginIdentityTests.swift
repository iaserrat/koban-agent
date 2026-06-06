import Foundation
import Testing
@testable import Koban_Agent

/// The same plugin can be named under several settings keys (`enabledPlugins`, `plugins`, ...).
/// It must surface as one inventory item, not duplicate rows competing for the same identity.
struct ClaudeSettingsPluginIdentityTests {
    @Test
    func pluginNamedInMultipleSettingsKeysIsOneItem() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(component: ".claude.json")
            try Data("{}".utf8).write(to: configURL)
            let settingsURL = directory.appending(path: ".claude/settings.json")
            try writeFile(
                settingsURL,
                contents: #"{"enabledPlugins": ["acme"], "plugins": {"acme": {}}}"#
            )
            let collector = ClaudeConfigCollector(configURL: configURL, settingsURLs: [settingsURL])

            let plugins = try await collector.snapshot().filter { $0.kind == .plugin && $0.name == "acme" }

            #expect(plugins.count == 1)
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
