import Foundation

// MARK: - ConfigurationFileValidationError

enum ConfigurationFileValidationError: Error, Equatable {
    case fileTooLarge(bytes: Int, maxBytes: Int)
}
