import Foundation
import Testing
@testable import Koban_Agent

struct ClaudeConfigCollectorHashIssueTests {
    @Test
    func instructionHashFailureReportsIssueAndKeepsItem() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let instructionURL = directory.appending(path: KnownPaths.claudeInstructionsName)
            try Data("# Instructions".utf8).write(to: instructionURL)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0],
                ofItemAtPath: instructionURL.path
            )

            let collector = ClaudeConfigCollector(
                configURLs: [],
                instructionURLs: [instructionURL]
            )

            let snapshot = try await collector.collect()

            let instruction = try #require(snapshot.items.first)
            #expect(instruction.kind == .instruction)
            #expect(instruction.name == KnownPaths.claudeInstructionsName)
            #expect(instruction.provenance.detail == nil)
            #expect(snapshot.issues.count == 1)
            let issue = try #require(snapshot.issues.first)
            #expect(issue.path == instructionURL.path)
            #expect(issue.reason.hasPrefix(HealthMessages.fileHashUnavailablePrefix))
        }
    }
}
