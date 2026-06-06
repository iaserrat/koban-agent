import Foundation

/// Small filesystem helpers shared by collectors. Keeps `FileManager` ceremony out of the
/// collection logic.
enum FileSystem {
    /// The immediate subdirectories of `root`, sorted by name. Returns an empty array when
    /// `root` does not exist or cannot be read - an absent surface is not an error.
    static func subdirectories(of root: URL) throws -> [URL] {
        try subdirectoryListing(of: root).subdirectories
    }

    static func subdirectoryListing(
        of root: URL,
        maxEntries: Int = ConfigurationDefaults.directoryListingMaxEntries
    ) throws -> FileSystemDirectoryListing {
        try Task.checkCancellation()
        let keys: [URLResourceKey] = [.isDirectoryKey]
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            return FileSystemDirectoryListing(subdirectories: [], issues: [])
        }
        guard isDirectory.boolValue else {
            return FileSystemDirectoryListing(
                subdirectories: [],
                issues: [directoryEnumerationIssue(at: root)]
            )
        }

        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else {
            return FileSystemDirectoryListing(subdirectories: [], issues: [
                directoryEnumerationIssue(at: root)
            ])
        }
        return try listing(from: enumerator, root: root, keys: keys, maxEntries: maxEntries)
    }

    private static func listing(
        from enumerator: FileManager.DirectoryEnumerator,
        root: URL,
        keys: [URLResourceKey],
        maxEntries: Int
    ) throws -> FileSystemDirectoryListing {
        var subdirectories: [URL] = []
        var issues: [CollectorIssue] = []
        var entriesVisited = 0
        for entry in enumerator {
            try Task.checkCancellation()
            entriesVisited += 1
            guard entriesVisited <= maxEntries else {
                issues.append(directoryEnumerationLimitIssue(at: root, maxEntries: maxEntries))
                break
            }
            guard let url = entry as? URL else { continue }
            appendSubdirectory(url, keys: keys, subdirectories: &subdirectories, issues: &issues)
        }
        return FileSystemDirectoryListing(
            subdirectories: subdirectories.sorted {
                $0.lastPathComponent < $1.lastPathComponent
            },
            issues: issues
        )
    }

    private static func appendSubdirectory(
        _ url: URL,
        keys: [URLResourceKey],
        subdirectories: inout [URL],
        issues: inout [CollectorIssue]
    ) {
        do {
            if try url.resourceValues(forKeys: Set(keys)).isDirectory == true {
                subdirectories.append(url)
            }
        } catch {
            issues.append(CollectorIssue(
                path: url.path,
                reason: "\(HealthMessages.directoryEnumerationUnavailable): \(error)"
            ))
        }
    }

    private static func directoryEnumerationIssue(
        at url: URL,
        error: (any Error)? = nil
    ) -> CollectorIssue {
        guard let error else {
            return CollectorIssue(path: url.path, reason: HealthMessages.directoryEnumerationUnavailable)
        }
        return CollectorIssue(
            path: url.path,
            reason: "\(HealthMessages.directoryEnumerationUnavailable): \(error)"
        )
    }

    private static func directoryEnumerationLimitIssue(
        at url: URL,
        maxEntries: Int
    ) -> CollectorIssue {
        CollectorIssue(
            path: url.path,
            reason: HealthMessages.directoryEnumerationEntryLimitReached(maxEntries: maxEntries)
        )
    }
}
