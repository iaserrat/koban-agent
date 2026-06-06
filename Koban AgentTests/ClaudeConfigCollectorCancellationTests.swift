import Foundation
import Testing
@testable import Koban_Agent

// MARK: - ClaudeConfigCollectorCancellationTests

struct ClaudeConfigCollectorCancellationTests {
    @Test
    func cancelledTaskStopsConfigCollection() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: ".claude.json")
            try writeFile(configURL, contents: #"{"mcpServers":{"docs":{"command":"npx"}}}"#)
            let collector = ClaudeConfigCollector(
                configURLs: [configURL]
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

    @Test
    func cancelledTaskStopsSettingsCollection() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let settingsURL = directory.appending(path: ".claude/settings.json")
            try writeFile(settingsURL, contents: #"{"hooks":{"before_run":["echo ok"]}}"#)
            let collector = ClaudeConfigCollector(
                configURLs: [],
                settingsURLs: [settingsURL]
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

    @Test
    func cancelledTaskStopsPluginCollection() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let pluginURL = directory.appending(path: ".claude/plugins/plugin.json")
            try writeFile(pluginURL, contents: #"{"name":"reviewer"}"#)
            let collector = ClaudeConfigCollector(
                configURLs: [],
                pluginURLs: [pluginURL]
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
}

private func writeFile(_ url: URL, contents: String) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try Data(contents.utf8).write(to: url)
}
