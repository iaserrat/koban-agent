import Foundation
import Testing
@testable import Koban_Agent

// MARK: - TOMLDocumentReaderTests

struct TOMLDocumentReaderTests {
    @Test
    func cancelledTaskStopsDecodeBeforeReading() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "config.toml")
            try #"name = "config""#.write(to: url, atomically: true, encoding: .utf8)
            let task = Task {
                try TOMLDocumentReader().decode(TOMLDocumentReaderFixture.self, from: url)
            }
            task.cancel()

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }
}

// MARK: - TOMLDocumentReaderFixture

private struct TOMLDocumentReaderFixture: Decodable {
    let name: String
}
