import Foundation
import Testing
@testable import Koban_Agent

// MARK: - PiConfigCollectorCancellationTests

struct PiConfigCollectorCancellationTests {
    @Test
    func cancelledTaskStopsMCPConfigCollection() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let mcpURL = directory.appending(path: ".pi/agent/mcp.json")
            try writeFile(mcpURL, contents: #"{"mcpServers":{"docs":{"command":"npx"}}}"#)
            let collector = PiConfigCollector(
                mcpConfigURLs: [mcpURL],
                settingsURLs: [],
                packageDirectories: [],
                includeImports: true
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
            let settingsURL = directory.appending(path: ".pi/agent/settings.json")
            try writeFile(settingsURL, contents: #"{"autoAuth":true}"#)
            let collector = PiConfigCollector(
                mcpConfigURLs: [],
                settingsURLs: [settingsURL],
                packageDirectories: [],
                includeImports: true
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
