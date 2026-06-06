import Foundation

struct PackageMetadataFileValidator {
    let maxBytes: Int

    init(maxBytes: Int = ConfigurationDefaults.packageMetadataMaxFileBytes) {
        self.maxBytes = maxBytes
    }

    func issueIfTooLarge(_ url: URL) throws -> CollectorIssue? {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = values.fileSize, fileSize > maxBytes else { return nil }
        return CollectorIssue(
            path: url.path,
            reason: HealthMessages.packageMetadataFileTooLarge(
                bytes: fileSize,
                maxBytes: maxBytes
            )
        )
    }
}
