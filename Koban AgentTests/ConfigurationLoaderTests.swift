import Foundation
import Testing
@testable import Koban_Agent

// MARK: - ConfigurationLoaderTests

struct ConfigurationLoaderTests {
    @Test
    func validUserConfigLoadsFromExplicitURL() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "koban.yaml")
            try writeFile(url, contents: "watch:\n  debounceMilliseconds: 123\n")

            let config = ConfigurationLoader.load(from: url)

            #expect(config.watch.debounceMilliseconds == 123)
        }
    }

    @Test
    func oversizedUserConfigFallsBackToDefaultsWithoutReading() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "koban.yaml")
            try writeFile(url, contents: String(repeating: " ", count: 101))

            let config = ConfigurationLoader.load(
                from: url,
                validator: ConfigurationFileValidator(maxBytes: 100)
            )

            #expect(config == DefaultConfiguration.value)
        }
    }

    @Test
    func configurationValidatorReportsOversizedFiles() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "koban.yaml")
            try writeFile(url, contents: String(repeating: " ", count: 101))

            #expect(throws: ConfigurationFileValidationError.fileTooLarge(bytes: 101, maxBytes: 100)) {
                try ConfigurationFileValidator(maxBytes: 100).validate(url)
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
}
