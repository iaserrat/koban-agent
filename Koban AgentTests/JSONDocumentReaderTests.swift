import Foundation
import Testing
@testable import Koban_Agent

// MARK: - JSONDocumentReaderTests

struct JSONDocumentReaderTests {
    @Test
    func cancelledTaskStopsDecodeBeforeReading() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "config.json")
            try #"{"name": "config"}"#.write(to: url, atomically: true, encoding: .utf8)
            let task = Task {
                try JSONDocumentReader().decode(JSONDocumentReaderFixture.self, from: url)
            }
            task.cancel()

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }
}

// MARK: - JSONDocumentReaderFixture

private struct JSONDocumentReaderFixture: Decodable {
    let name: String
}
