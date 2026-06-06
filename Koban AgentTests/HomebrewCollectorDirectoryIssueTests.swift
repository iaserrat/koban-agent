import Foundation
import Testing
@testable import Koban_Agent

struct HomebrewCollectorDirectoryIssueTests {
    private let invalidDirectoryContents = "not a directory"

    @Test
    func invalidCellarRootReportsIssue() async throws {
        try await Fixture.withTemporaryDirectory { prefix in
            let cellar = prefix.appending(path: KnownPaths.homebrewCellarComponent)
            try Data(invalidDirectoryContents.utf8).write(to: cellar)

            let collector = HomebrewCollector(prefixes: [prefix])
            let snapshot = try await collector.collect()

            #expect(snapshot.items.isEmpty)
            #expect(snapshot.issues.count == 1)
            let issue = try #require(snapshot.issues.first)
            #expect(issue.path == cellar.path)
            #expect(issue.reason == HealthMessages.directoryEnumerationUnavailable)
        }
    }

    @Test
    func invalidCaskroomRootReportsIssue() async throws {
        try await Fixture.withTemporaryDirectory { prefix in
            let caskroom = prefix.appending(path: KnownPaths.homebrewCaskroomComponent)
            try Data(invalidDirectoryContents.utf8).write(to: caskroom)

            let collector = HomebrewCollector(prefixes: [prefix])
            let snapshot = try await collector.collect()

            #expect(snapshot.items.isEmpty)
            #expect(snapshot.issues.count == 1)
            let issue = try #require(snapshot.issues.first)
            #expect(issue.path == caskroom.path)
            #expect(issue.reason == HealthMessages.directoryEnumerationUnavailable)
        }
    }
}
