import Foundation

// MARK: - DatabaseRuntimeDefaults

enum DatabaseRuntimeDefaults {
    static let busyTimeoutSeconds: TimeInterval = 2
    static let maximumReaderCount = 4
    static let synchronousNormalValue = 1
}
