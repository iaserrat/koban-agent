import Foundation

// MARK: - ProjectFileDiscoverer

/// Discovers known project metadata files under bounded roots.
struct ProjectFileDiscoverer {
    private let roots: [String]
    private let includeFileNames: Set<String>
    private let includeFileGlobs: [String]
    private let excludeDirectoryNames: Set<String>
    private let maxDepth: Int
    private let budget: ProjectFileDiscoveryBudget
    private let now: @Sendable () -> Date
    private let resourceValues: @Sendable (URL, Set<URLResourceKey>) throws -> URLResourceValues

    var rootPaths: [String] {
        roots
    }

    init(
        roots: [String],
        includeFileNames: [String],
        includeFileGlobs: [String],
        excludeDirectoryNames: [String],
        maxDepth: Int,
        budget: ProjectFileDiscoveryBudget = .defaultValue,
        now: @escaping @Sendable () -> Date = Date.init,
        resourceValues: @escaping @Sendable (URL, Set<URLResourceKey>) throws -> URLResourceValues = {
            try $0.resourceValues(forKeys: $1)
        }
    ) {
        self.roots = roots
        self.includeFileNames = Set(includeFileNames)
        self.includeFileGlobs = includeFileGlobs
        self.excludeDirectoryNames = Set(excludeDirectoryNames)
        self.maxDepth = maxDepth
        self.budget = budget
        self.now = now
        self.resourceValues = resourceValues
    }

    func candidateFiles() throws -> [URL] {
        try candidateFileResult().files
    }

    func candidateFileResult() throws -> ProjectFileDiscoveryResult {
        var state = ProjectFileDiscoveryState(startedAt: now())
        for root in roots {
            try Task.checkCancellation()
            let url = KnownPaths.configuredURL(root, directoryHint: .isDirectory)
            try collect(from: url, depth: DiscoveryDepth.root, state: &state)
        }
        state.result.files = state.result.files.sorted { $0.path < $1.path }
        return state.result
    }

    private func collect(
        from directory: URL,
        depth: Int,
        state: inout ProjectFileDiscoveryState
    ) throws {
        try Task.checkCancellation()
        guard depth <= maxDepth else { return }
        guard isWithinWallClockBudget(state.startedAt) else {
            state.result.issues.append(projectDiscoveryWallClockIssue(directory, budget: budget))
            return
        }
        guard canVisit(directory, state: &state) else { return }

        var enumerationIssues: [CollectorIssue] = []
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants, .skipsSubdirectoryDescendants],
            errorHandler: { url, error in
                enumerationIssues.append(projectDirectoryEnumerationIssue(at: url, error: error))
                return true
            }
        ) else {
            state.result.issues.append(projectDirectoryEnumerationIssue(at: directory))
            return
        }

        for case let url as URL in enumerator {
            guard try inspect(url, directory: directory, depth: depth, state: &state) else {
                state.result.issues.append(contentsOf: enumerationIssues)
                return
            }
        }
        state.result.issues.append(contentsOf: enumerationIssues)
    }

    private func inspect(
        _ url: URL,
        directory: URL,
        depth: Int,
        state: inout ProjectFileDiscoveryState
    ) throws -> Bool {
        try Task.checkCancellation()
        guard isWithinWallClockBudget(state.startedAt) else {
            state.result.issues.append(projectDiscoveryWallClockIssue(url, budget: budget))
            return false
        }
        let name = url.lastPathComponent
        let values: URLResourceValues
        do {
            values = try resourceValues(url, [.isDirectoryKey])
        } catch {
            state.result.issues.append(projectDirectoryEnumerationIssue(at: url, error: error))
            return true
        }
        if values.isDirectory == true {
            guard excludeDirectoryNames.contains(name) == false else { return true }
            try collect(from: url, depth: depth + DiscoveryDepth.child, state: &state)
            return true
        }
        guard FilenameMatcher.matches(
            name: name,
            exactNames: includeFileNames,
            globs: includeFileGlobs
        ) else {
            return true
        }
        guard state.result.files.count < budget.maxFilesMatched else {
            state.result.issues.append(projectDiscoveryLimitIssue(directory, budget: budget))
            return false
        }
        state.result.files.append(url)
        return true
    }

    private func canVisit(
        _ directory: URL,
        state: inout ProjectFileDiscoveryState
    ) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) else {
            return false
        }
        guard isDirectory.boolValue else {
            state.result.issues.append(projectDirectoryEnumerationIssue(at: directory))
            return false
        }
        guard state.directoriesVisited < budget.maxDirectoriesVisited else {
            state.result.issues.append(projectDiscoveryLimitIssue(directory, budget: budget))
            return false
        }
        state.directoriesVisited += 1
        return true
    }

    private func isWithinWallClockBudget(_ startedAt: Date) -> Bool {
        now().timeIntervalSince(startedAt) <= TimeInterval(budget.maxWallClockSeconds)
    }
}

private func projectDirectoryEnumerationIssue(at url: URL) -> CollectorIssue {
    CollectorIssue(path: url.path, reason: HealthMessages.directoryEnumerationUnavailable)
}

private func projectDirectoryEnumerationIssue(at url: URL, error: any Error) -> CollectorIssue {
    CollectorIssue(
        path: url.path,
        reason: "\(HealthMessages.directoryEnumerationUnavailable): \(error)"
    )
}

private func projectDiscoveryLimitIssue(
    _ directory: URL,
    budget: ProjectFileDiscoveryBudget
) -> CollectorIssue {
    CollectorIssue(
        path: directory.path,
        reason: HealthMessages.projectDiscoveryLimitReached(
            maxDirectories: budget.maxDirectoriesVisited,
            maxFiles: budget.maxFilesMatched
        )
    )
}

private func projectDiscoveryWallClockIssue(
    _ url: URL,
    budget: ProjectFileDiscoveryBudget
) -> CollectorIssue {
    CollectorIssue(
        path: url.path,
        reason: HealthMessages.directoryEnumerationTimeLimitReached(
            seconds: budget.maxWallClockSeconds
        )
    )
}
