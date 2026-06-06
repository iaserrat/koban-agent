import Foundation
import Testing
@testable import Koban_Agent

struct HomebrewCollectorReceiptIssueTests {
    @Test
    func malformedFormulaReceiptReportsIssueAndKeepsPackage() async throws {
        try await Fixture.withTemporaryDirectory { prefix in
            let receiptURL = prefix.appending(path: "Cellar/ripgrep/14.0/INSTALL_RECEIPT.json")
            try writeFile(receiptURL, contents: "{")

            let collector = HomebrewCollector(prefixes: [prefix])
            let snapshot = try await collector.collect()

            let item = try #require(snapshot.items.first)
            #expect(item.name == "ripgrep")
            #expect(item.provenance.origin == HomebrewLabels.unknownTap)
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.path.hasSuffix(
                "/Cellar/ripgrep/14.0/INSTALL_RECEIPT.json"
            ) == true)
        }
    }

    @Test
    func malformedCaskReceiptReportsIssueAndKeepsCask() async throws {
        try await Fixture.withTemporaryDirectory { prefix in
            let versionURL = prefix.appending(path: "Caskroom/firefox/120.0")
            try FileManager.default.createDirectory(at: versionURL, withIntermediateDirectories: true)
            let receiptURL = prefix.appending(path: "Caskroom/firefox/.metadata/INSTALL_RECEIPT.json")
            try writeFile(receiptURL, contents: "{")

            let collector = HomebrewCollector(prefixes: [prefix])
            let snapshot = try await collector.collect()

            let item = try #require(snapshot.items.first)
            #expect(item.name == "firefox")
            #expect(item.provenance.origin == HomebrewLabels.unknownTap)
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.path.hasSuffix(
                "/Caskroom/firefox/.metadata/INSTALL_RECEIPT.json"
            ) == true)
        }
    }

    @Test
    func oversizedReceiptReportsIssueAndKeepsPackage() async throws {
        try await Fixture.withTemporaryDirectory { prefix in
            let receiptURL = prefix.appending(path: "Cellar/ripgrep/14.0/INSTALL_RECEIPT.json")
            try writeFile(receiptURL, contents: String(repeating: " ", count: 101))

            let collector = HomebrewCollector(
                prefixes: [prefix],
                receiptValidator: HomebrewReceiptFileValidator(maxBytes: 100)
            )
            let snapshot = try await collector.collect()

            let item = try #require(snapshot.items.first)
            #expect(item.name == "ripgrep")
            #expect(item.provenance.origin == HomebrewLabels.unknownTap)
            #expect(snapshot.issues.count == 1)
            #expect(snapshot.issues.first?.path.hasSuffix(
                "/Cellar/ripgrep/14.0/INSTALL_RECEIPT.json"
            ) == true)
            #expect(snapshot.issues.first?.reason == HealthMessages.homebrewReceiptFileTooLarge(
                bytes: 101,
                maxBytes: 100
            ))
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
