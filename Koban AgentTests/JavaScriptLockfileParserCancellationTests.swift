import Foundation
import Testing
@testable import Koban_Agent

// MARK: - JavaScriptLockfileParserCancellationTests

struct JavaScriptLockfileParserCancellationTests {
    @Test
    func cancelledTaskStopsNpmLockfileParsing() async throws {
        try await expectCancellation(for: "package-lock.json", contents: #"{"packages": {}}"#) { url in
            try NpmLockfileParser().records(from: url, manager: PackageMetadataNames.npmManager)
        }
    }

    @Test
    func cancelledTaskStopsPnpmLockfileParsing() async throws {
        try await expectCancellation(for: "pnpm-lock.yaml", contents: "packages: {}\n") { url in
            try PnpmLockfileParser().records(from: url)
        }
    }

    @Test
    func cancelledTaskStopsYarnLockfileParsing() async throws {
        try await expectCancellation(
            for: "yarn.lock",
            contents: "\"left-pad@^1.0.0\":\n  version \"1.0.0\"\n"
        ) { url in
            try YarnLockfileParser().records(from: url)
        }
    }

    @Test
    func cancelledTaskStopsBunLockfileParsing() async throws {
        try await expectCancellation(for: "bun.lock", contents: #"{"packages": {}}"#) { url in
            try BunLockfileParser().records(from: url)
        }
    }

    private func expectCancellation(
        for filename: String,
        contents: String,
        parse: @escaping @Sendable (URL) throws -> [PackageInventoryRecord]
    ) async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: filename)
            try contents.write(to: url, atomically: true, encoding: .utf8)
            let task = Task {
                try parse(url)
            }
            task.cancel()

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }
}
