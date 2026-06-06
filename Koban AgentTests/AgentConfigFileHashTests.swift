import Foundation
import Testing
@testable import Koban_Agent

// MARK: - AgentConfigFileHashTests

struct AgentConfigFileHashTests {
    @Test
    func oversizedFilesDoNotGetHashedAndReportVisibilityIssue() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "large.md")
            try Data(repeating: 1, count: 101).write(to: url)

            let result = AgentConfigFileHash.detail(
                for: url,
                validator: AgentConfigFileValidator(maxBytes: 100)
            )

            #expect(result.detail == nil)
            let issue = try #require(result.issue)
            #expect(issue.path == url.path)
            #expect(issue.reason == HealthMessages.agentConfigFileTooLarge(bytes: 101, maxBytes: 100))
        }
    }
}
