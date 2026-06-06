import Foundation
import Testing
@testable import Koban_Agent

// MARK: - PythonRequirementParserCancellationTests

struct PythonRequirementParserCancellationTests {
    @Test
    func cancelledTaskStopsRequirementParsing() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "requirements.txt")
            try "flask==3.0\n".write(to: url, atomically: true, encoding: .utf8)
            let task = Task {
                try PythonRequirementParser().records(from: url, kind: .pythonDeclaredRequirement)
            }
            task.cancel()

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }
}
