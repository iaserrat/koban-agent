import Foundation
import Testing
@testable import Koban_Agent

// MARK: - FileSystemTests

struct FileSystemTests {
    @Test
    func subdirectoryListingStopsAtEntryLimitAndReportsIssue() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try FileManager.default.createDirectory(
                at: directory.appending(path: "one"),
                withIntermediateDirectories: true
            )
            try FileManager.default.createDirectory(
                at: directory.appending(path: "two"),
                withIntermediateDirectories: true
            )

            let listing = try FileSystem.subdirectoryListing(of: directory, maxEntries: 1)

            #expect(listing.subdirectories.count == 1)
            #expect(listing.issues == [
                CollectorIssue(
                    path: directory.path,
                    reason: HealthMessages.directoryEnumerationEntryLimitReached(maxEntries: 1)
                )
            ])
        }
    }

    @Test
    func cancelledTaskStopsSubdirectoryListing() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try FileManager.default.createDirectory(
                at: directory.appending(path: "one"),
                withIntermediateDirectories: true
            )
            let task = Task {
                try FileSystem.subdirectoryListing(of: directory)
            }
            task.cancel()

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }

    @Test
    func subdirectoryListingKeepsSortedImmediateDirectories() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            try FileManager.default.createDirectory(
                at: directory.appending(path: "zeta"),
                withIntermediateDirectories: true
            )
            try FileManager.default.createDirectory(
                at: directory.appending(path: "alpha"),
                withIntermediateDirectories: true
            )
            try Data().write(to: directory.appending(path: "file.txt"))

            let listing = try FileSystem.subdirectoryListing(of: directory)

            #expect(listing.subdirectories.map(\.lastPathComponent) == ["alpha", "zeta"])
            #expect(listing.issues.isEmpty)
        }
    }
}
