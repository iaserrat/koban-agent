enum HealthMessages {
    static let watchStreamUnavailable = "FSEvents stream unavailable"
    static let watchEventsDropped = "FSEvents events dropped"
    static let watchEventIDsWrapped = "FSEvents event IDs wrapped"
    static let watchRootChanged = "FSEvents watched root changed"
    static let directoryEnumerationUnavailable = "Directory could not be enumerated"

    static func directoryEnumerationLimitReached(maxEntries: Int, maxFiles: Int) -> String {
        "Directory enumeration stopped after \(maxEntries) entries or \(maxFiles) files"
    }

    static func directoryEnumerationEntryLimitReached(maxEntries: Int) -> String {
        "Directory enumeration stopped after \(maxEntries) entries"
    }

    static func directoryEnumerationTimeLimitReached(seconds: Int) -> String {
        "Directory enumeration stopped after \(seconds) seconds"
    }

    static func projectDiscoveryLimitReached(maxDirectories: Int, maxFiles: Int) -> String {
        "Project discovery stopped after \(maxDirectories) directories or \(maxFiles) files"
    }

    static func packageMetadataFileTooLarge(bytes: Int, maxBytes: Int) -> String {
        "Package metadata file is \(bytes) bytes, over the \(maxBytes) byte scan limit"
    }

    static func pythonRequirementIncludeLimitReached(maxFiles: Int, maxDepth: Int) -> String {
        "Python requirement include limit reached: max files \(maxFiles), max depth \(maxDepth)"
    }

    static func agentConfigFileTooLarge(bytes: Int, maxBytes: Int) -> String {
        "Agent config file is \(bytes) bytes, over the \(maxBytes) byte scan limit"
    }

    static func homebrewReceiptFileTooLarge(bytes: Int, maxBytes: Int) -> String {
        "Homebrew receipt file is \(bytes) bytes, over the \(maxBytes) byte scan limit"
    }

    static let fileHashUnavailablePrefix = "File hash unavailable"
    static let fileIsNotRegular = "File is not a regular file"

    static func fileHashUnavailable(error: any Error) -> String {
        "\(fileHashUnavailablePrefix): \(error)"
    }

    static func scanTimedOut(seconds: Int) -> String {
        "Scan timed out after \(seconds) seconds"
    }

    static func collectorVisibilityIssues(count: Int, firstIssue: CollectorIssue?) -> String {
        guard let firstIssue else {
            return "Collector reported \(count) visibility issues"
        }
        return "Collector reported \(count) visibility issues; first: "
            + "\(firstIssue.path): \(firstIssue.reason)"
    }

    static func homeSignalDiscoveryIssues(count: Int, firstIssue: CollectorIssue?) -> String {
        guard let firstIssue else {
            return "Home signal discovery reported \(count) visibility issues"
        }
        return "Home signal discovery reported \(count) visibility issues; first: "
            + "\(firstIssue.path): \(firstIssue.reason)"
    }

    static func scanFailureRecordingFailed(scanError: any Error, healthError: any Error) -> String {
        "Scan failed with \(scanError), then failure persistence failed with \(healthError)"
    }
}
