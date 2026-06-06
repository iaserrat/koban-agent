import Foundation
import Testing
@testable import Koban_Agent

// MARK: - ProjectFileDiscovererCancellationTests

struct ProjectFileDiscovererCancellationTests {
    @Test
    func cancelledTaskStopsDiscovery() async throws {
        try await Fixture.withTemporaryDirectory { root in
            try writeProjectFile(root.appending(path: "app/package-lock.json"))

            let discoverer = ProjectFileDiscoverer(
                roots: [root.path],
                includeFileNames: ["package-lock.json"],
                includeFileGlobs: [],
                excludeDirectoryNames: [],
                maxDepth: 2
            )

            let task = Task {
                withUnsafeCurrentTask { task in
                    task?.cancel()
                }
                return try discoverer.candidateFileResult()
            }

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }
}

private func writeProjectFile(_ url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try Data().write(to: url)
}
