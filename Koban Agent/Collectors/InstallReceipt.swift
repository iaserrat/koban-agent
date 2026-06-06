import Foundation

/// The subset of Homebrew's `INSTALL_RECEIPT.json` that Koban uses for provenance. Homebrew
/// writes one per installed keg; we read only the originating tap and whether the install was
/// requested explicitly.
struct InstallReceipt: Decodable {
    struct Source: Decodable {
        var tap: String?
    }

    var source: Source?
    var installedOnRequest: Bool?

    private enum CodingKeys: String, CodingKey {
        case source
        case installedOnRequest = "installed_on_request"
    }

    /// Reads and decodes the receipt inside `kegDirectory`, or `nil` if absent.
    static func read(
        inKeg kegDirectory: URL,
        validator: HomebrewReceiptFileValidator = HomebrewReceiptFileValidator()
    ) throws -> InstallReceiptReadResult {
        let url = kegDirectory.appending(component: KnownPaths.homebrewInstallReceiptName)
        return try read(at: url, validator: validator)
    }

    /// Reads and decodes the cask receipt under `Caskroom/<name>/.metadata`, or `nil` if absent.
    static func read(
        inCaskMetadata caskDirectory: URL,
        validator: HomebrewReceiptFileValidator = HomebrewReceiptFileValidator()
    ) throws -> InstallReceiptReadResult {
        let url = caskDirectory
            .appending(component: KnownPaths.homebrewMetadataComponent, directoryHint: .isDirectory)
            .appending(component: KnownPaths.homebrewInstallReceiptName)
        return try read(at: url, validator: validator)
    }

    private static func read(
        at url: URL,
        validator: HomebrewReceiptFileValidator
    ) throws -> InstallReceiptReadResult {
        try Task.checkCancellation()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return InstallReceiptReadResult(receipt: nil, issue: nil)
        }
        do {
            try Task.checkCancellation()
            if let issue = try validator.issueIfTooLarge(url) {
                return InstallReceiptReadResult(receipt: nil, issue: issue)
            }
            try Task.checkCancellation()
            let data = try Data(contentsOf: url)
            try Task.checkCancellation()
            let receipt = try JSONDecoder().decode(Self.self, from: data)
            return InstallReceiptReadResult(receipt: receipt, issue: nil)
        } catch let error as CancellationError {
            throw error
        } catch {
            return InstallReceiptReadResult(
                receipt: nil,
                issue: CollectorIssue(path: url.path, reason: String(describing: error))
            )
        }
    }
}
