import Foundation
import Testing
@testable import Koban_Agent

// MARK: - OpenCodeConfigCollectorCancellationTests

struct OpenCodeConfigCollectorCancellationTests {
    @Test
    func cancelledTaskStopsConfigCollection() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let configURL = directory.appending(path: ".config/opencode/opencode.json")
            try writeFile(configURL, contents: #"{"mcp":{"docs":{"command":"npx"}}}"#)
            let collector = OpenCodeConfigCollector(
                configURLs: [configURL],
                agentDirectories: [],
                commandDirectories: [],
                pluginDirectories: [],
                instructionURLs: [],
                includeMCP: true
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
