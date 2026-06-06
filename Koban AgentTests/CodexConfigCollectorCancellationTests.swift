import Foundation
import Testing
@testable import Koban_Agent

// MARK: - CodexConfigCollectorCancellationTests

struct CodexConfigCollectorCancellationTests {
    @Test
    func cancelledTaskStopsConfigCollection() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: ".codex/config.toml")
            try writeFile(
                configURL,
                contents: "[mcp_servers.docs]\ncommand = \"npx\"\n"
            )
            let collector = CodexConfigCollector(
                configURLs: [configURL],
                hooksURLs: [],
                rulesDirectories: [],
                skillsDirectories: []
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
    func cancelledTaskStopsHooksCollection() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let hooksURL = directory.appending(path: ".codex/hooks.json")
            try writeFile(hooksURL, contents: #"{"before_run": "echo ok"}"#)
            let collector = CodexConfigCollector(
                configURLs: [],
                hooksURLs: [hooksURL],
                rulesDirectories: [],
                skillsDirectories: []
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
