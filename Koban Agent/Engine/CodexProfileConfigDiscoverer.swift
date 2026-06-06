import Foundation

enum CodexProfileConfigDiscoverer {
    static func result(for settings: CodexSettings) throws -> CodexProfileConfigDiscoveryResult {
        try Task.checkCancellation()
        guard let glob = settings.profileConfigGlob else {
            return CodexProfileConfigDiscoveryResult(files: [], issues: [])
        }
        return try result(matching: glob)
    }

    static func result(
        matching glob: String,
        maxEntries: Int = ConfigurationDefaults.directoryListingMaxEntries
    ) throws -> CodexProfileConfigDiscoveryResult {
        try Task.checkCancellation()
        let globURL = KnownPaths.configuredURL(glob)
        let directory = globURL.deletingLastPathComponent()
        let fileGlob = globURL.lastPathComponent
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) else {
            return CodexProfileConfigDiscoveryResult(files: [], issues: [])
        }
        guard isDirectory.boolValue else {
            return CodexProfileConfigDiscoveryResult(files: [], issues: [
                CollectorIssue(path: directory.path, reason: HealthMessages.directoryEnumerationUnavailable)
            ])
        }

        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else {
            return CodexProfileConfigDiscoveryResult(files: [], issues: [
                CollectorIssue(path: directory.path, reason: HealthMessages.directoryEnumerationUnavailable)
            ])
        }
        return try result(from: enumerator, directory: directory, fileGlob: fileGlob, maxEntries: maxEntries)
    }

    private static func result(
        from enumerator: FileManager.DirectoryEnumerator,
        directory: URL,
        fileGlob: String,
        maxEntries: Int
    ) throws -> CodexProfileConfigDiscoveryResult {
        var result = CodexProfileConfigDiscoveryResult(files: [], issues: [])
        var entriesVisited = 0
        for entry in enumerator {
            try Task.checkCancellation()
            entriesVisited += 1
            guard entriesVisited <= maxEntries else {
                result.issues.append(directoryEnumerationLimitIssue(at: directory, maxEntries: maxEntries))
                break
            }
            guard let url = entry as? URL else { continue }
            append(url, matching: fileGlob, to: &result)
        }
        return CodexProfileConfigDiscoveryResult(
            files: result.files.sorted { $0.lastPathComponent < $1.lastPathComponent },
            issues: result.issues
        )
    }

    private static func append(
        _ url: URL,
        matching fileGlob: String,
        to result: inout CodexProfileConfigDiscoveryResult
    ) {
        do {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true,
                  FilenameMatcher.matches(name: url.lastPathComponent, exactNames: [], globs: [fileGlob])
            else { return }
            result.files.append(url)
        } catch {
            result.issues.append(CollectorIssue(
                path: url.path,
                reason: "\(HealthMessages.directoryEnumerationUnavailable): \(error)"
            ))
        }
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
