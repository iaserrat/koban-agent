import Foundation
import Testing
@testable import Koban_Agent

struct HomebrewCollectorTests {
    @Test
    func collectsFormulaeAndCasksWithProvenance() async throws {
        try await Fixture.withTemporaryDirectory { prefix in
            try makeFormula(
                in: prefix,
                name: "ripgrep",
                version: "14.0",
                tap: "homebrew/core",
                onRequest: true
            )
            try makeFormula(
                in: prefix,
                name: "pcre2",
                version: "10.4",
                tap: "homebrew/core",
                onRequest: false
            )
            try makeCask(
                in: prefix,
                name: "firefox",
                version: "120.0",
                tap: "third-party/cask",
                onRequest: true
            )

            let collector = HomebrewCollector(prefixes: [prefix])
            let items = try await collector.snapshot()

            #expect(items.count == 3)
            let ripgrep = try #require(items.first { $0.name == "ripgrep" })
            #expect(ripgrep.version == "14.0")
            #expect(ripgrep.provenance.origin == "homebrew/core")
            #expect(ripgrep.provenance.installedOnRequest == true)

            let firefox = try #require(items.first { $0.name == "firefox" })
            #expect(firefox.provenance.origin == "third-party/cask")
            #expect(firefox.provenance.installedOnRequest == true)
        }
    }

    @Test
    func emptyPrefixYieldsNoItems() async throws {
        try await Fixture.withTemporaryDirectory { prefix in
            let collector = HomebrewCollector(prefixes: [prefix])
            let items = try await collector.snapshot()
            #expect(items.isEmpty)
        }
    }

    @Test
    func sameNameInDifferentPrefixesAreDistinctItems() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let armPrefix = directory.appending(component: "arm", directoryHint: .isDirectory)
            let intelPrefix = directory.appending(component: "intel", directoryHint: .isDirectory)
            try makeFormula(
                in: armPrefix,
                name: "openssl",
                version: "3.0",
                tap: "homebrew/core",
                onRequest: true
            )
            try makeFormula(
                in: intelPrefix,
                name: "openssl",
                version: "1.1",
                tap: "legacy/tap",
                onRequest: true
            )

            let collector = HomebrewCollector(prefixes: [armPrefix, intelPrefix])
            let items = try await collector.snapshot()

            #expect(items.count == 2)
            #expect(Set(items.map(\.id)).count == 2)
            #expect(Set(items.map(\.path)).count == 2)
        }
    }

    private func makeFormula(
        in prefix: URL,
        name: String,
        version: String,
        tap: String,
        onRequest: Bool
    ) throws {
        let keg = prefix.appending(path: "Cellar/\(name)/\(version)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: keg, withIntermediateDirectories: true)
        let receipt = #"{"installed_on_request": \#(onRequest), "source": {"tap": "\#(tap)"}}"#
        try Data(receipt.utf8).write(to: keg.appending(component: "INSTALL_RECEIPT.json"))
    }

    private func makeCask(
        in prefix: URL,
        name: String,
        version: String,
        tap: String,
        onRequest: Bool
    ) throws {
        let dir = prefix.appending(path: "Caskroom/\(name)/\(version)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let metadata = prefix.appending(path: "Caskroom/\(name)/.metadata", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: metadata, withIntermediateDirectories: true)
        let receipt = #"{"installed_on_request": \#(onRequest), "source": {"tap": "\#(tap)"}}"#
        try Data(receipt.utf8).write(to: metadata.appending(component: "INSTALL_RECEIPT.json"))
    }
}
