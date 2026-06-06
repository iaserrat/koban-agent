import Foundation

struct AgentConfigFileSearcher {
    let directory: URL
    let budget: AgentConfigFileSearchBudget
    let now: @Sendable () -> Date

    func run() throws -> AgentConfigFileSearchResult {
        try Task.checkCancellation()
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            return missingDirectoryResult()
        }

        var issues: [CollectorIssue] = []
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { url, error in
                issues.append(CollectorIssue(path: url.path, reason: String(describing: error)))
                return true
            }
        ) else {
            return unavailableDirectoryResult()
        }

        return try collectFiles(from: enumerator, issues: &issues)
    }

    private func collectFiles(
        from enumerator: FileManager.DirectoryEnumerator,
        issues: inout [CollectorIssue]
    ) throws -> AgentConfigFileSearchResult {
        var files: [URL] = []
        var entriesVisited = 0
        let startedAt = now()
        for entry in enumerator {
            try Task.checkCancellation()
            guard isWithinWallClockBudget(startedAt) else {
                issues.append(directoryEnumerationTimeLimitIssue())
                break
            }
            entriesVisited += 1
            let file = regularFileURL(from: entry, issues: &issues)
            guard entriesVisited <= budget.maxEntries else {
                issues.append(directoryEnumerationLimitIssue())
                break
            }
            guard let file else { continue }
            guard files.count < budget.maxFiles else {
                issues.append(directoryEnumerationLimitIssue())
                break
            }
            files.append(file)
        }
        return AgentConfigFileSearchResult(files: files, issues: issues)
    }

    private func isWithinWallClockBudget(_ startedAt: Date) -> Bool {
        now().timeIntervalSince(startedAt) <= TimeInterval(budget.maxWallClockSeconds)
    }

    private func regularFileURL(
        from entry: Any,
        issues: inout [CollectorIssue]
    ) -> URL? {
        guard let url = entry as? URL else { return nil }
        do {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            return values.isRegularFile == true ? url : nil
        } catch {
            issues.append(CollectorIssue(path: url.path, reason: String(describing: error)))
            return nil
        }
    }

    private func missingDirectoryResult() -> AgentConfigFileSearchResult {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            return AgentConfigFileSearchResult(files: [], issues: [])
        }
        return unavailableDirectoryResult()
    }

    private func unavailableDirectoryResult() -> AgentConfigFileSearchResult {
        AgentConfigFileSearchResult(
            files: [],
            issues: [directoryEnumerationIssue()]
        )
    }

    private func directoryEnumerationIssue() -> CollectorIssue {
        CollectorIssue(
            path: directory.path,
            reason: HealthMessages.directoryEnumerationUnavailable
        )
    }

    private func directoryEnumerationLimitIssue() -> CollectorIssue {
        CollectorIssue(
            path: directory.path,
            reason: HealthMessages.directoryEnumerationLimitReached(
                maxEntries: budget.maxEntries,
                maxFiles: budget.maxFiles
            )
        )
    }

    private func directoryEnumerationTimeLimitIssue() -> CollectorIssue {
        CollectorIssue(
            path: directory.path,
            reason: HealthMessages.directoryEnumerationTimeLimitReached(
                seconds: budget.maxWallClockSeconds
            )
        )
    }
}
