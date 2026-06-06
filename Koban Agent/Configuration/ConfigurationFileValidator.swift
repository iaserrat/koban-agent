import Foundation

// MARK: - ConfigurationFileValidator

struct ConfigurationFileValidator {
    let maxBytes: Int

    init(maxBytes: Int = ConfigurationDefaults.configurationMaxFileBytes) {
        self.maxBytes = maxBytes
    }

    func validate(_ url: URL) throws {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = values.fileSize, fileSize > maxBytes else { return }
        throw ConfigurationFileValidationError.fileTooLarge(bytes: fileSize, maxBytes: maxBytes)
    }
}
