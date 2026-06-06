import Foundation

/// Targeted opt-in home discovery for known Koban signal files.
struct SignalFileDiscoverer {
    private let settings: HomeSignalScanSettings
    private let fileManager: FileManager
    private let now: () -> Date

    init(
        settings: HomeSignalScanSettings,
        fileManager: FileManager = .default,
        now: @escaping () -> Date = Date.init
    ) {
        self.settings = settings
        self.fileManager = fileManager
        self.now = now
    }

    func candidateFiles() throws -> [URL] {
        try candidateFileResult().files
    }

    func candidateFileResult() throws -> SignalFileDiscoveryResult {
        try Task.checkCancellation()
        guard settings.enabled else { return SignalFileDiscoveryResult(files: [], issues: []) }
        let root = URL(filePath: settings.root, directoryHint: .isDirectory)
        var state = SignalScanState(startedAt: now())
        try collect(from: root, depth: DiscoveryDepth.root, state: &state)
        return SignalFileDiscoveryResult(
            files: state.candidates.sorted { $0.path < $1.path },
            issues: state.issues
        )
    }

    private func collect(from directory: URL, depth: Int, state: inout SignalScanState) throws {
        try Task.checkCancellation()
        guard state.isExhausted == false, depth <= settings.maxDepth else { return }
        guard isWithinWallClockBudget(state) else {
            state.markExhausted()
            state.issues.append(wallClockIssue(at: directory))
            return
        }
        state.directoriesVisited += DiscoveryDepth.child
        guard state.directoriesVisited <= settings.initialScanBudget.maxDirectoriesVisited else {
            state.markExhausted()
            state.issues.append(budgetIssue(at: directory))
            return
        }

        var enumerationIssues: [CollectorIssue] = []
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey],
            options: [.skipsPackageDescendants, .skipsSubdirectoryDescendants],
            errorHandler: { url, error in
                enumerationIssues.append(directoryIssue(at: url, error: error))
                return true
            }
        ) else {
            state.issues.append(CollectorIssue(
                path: directory.path,
                reason: HealthMessages.directoryEnumerationUnavailable
            ))
            return
        }

        for case let url as URL in enumerator where state.isExhausted == false {
            try Task.checkCancellation()
            try inspect(url, depth: depth, state: &state)
        }
        state.issues.append(contentsOf: enumerationIssues)
    }

    private func inspect(_ url: URL, depth: Int, state: inout SignalScanState) throws {
        try Task.checkCancellation()
        guard isWithinWallClockBudget(state) else {
            state.markExhausted()
            state.issues.append(wallClockIssue(at: url))
            return
        }
        let name = url.lastPathComponent
        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey])
        } catch {
            state.issues.append(directoryIssue(at: url, error: error))
            return
        }

        if shouldDescend(name: name, values: values) {
            try collect(from: url, depth: depth + DiscoveryDepth.child, state: &state)
            return
        }

        guard values.isDirectory != true else { return }
        state.filesVisited += DiscoveryDepth.child
        guard state.filesVisited <= settings.initialScanBudget.maxFilesVisited else {
            state.markExhausted()
            state.issues.append(budgetIssue(at: url))
            return
        }
        if FilenameMatcher.matches(
            name: name,
            exactNames: Set(settings.signalFileNames),
            globs: settings.signalFileGlobs
        ) {
            state.candidates.append(url)
        }
    }

    private func shouldDescend(name: String, values: URLResourceValues) -> Bool {
        guard values.isDirectory == true else { return false }
        guard settings.pruneDirectoryNames.contains(name) == false else { return false }
        guard settings.followSymlinks || values.isSymbolicLink != true else { return false }
        return values.isPackage != true
    }

    private func isWithinWallClockBudget(_ state: SignalScanState) -> Bool {
        now().timeIntervalSince(state.startedAt)
            <= TimeInterval(settings.initialScanBudget.maxWallClockSeconds)
    }

    private func directoryIssue(at url: URL, error: any Error) -> CollectorIssue {
        CollectorIssue(
            path: url.path,
            reason: "\(HealthMessages.directoryEnumerationUnavailable): \(error)"
        )
    }

    private func budgetIssue(at url: URL) -> CollectorIssue {
        let budget = settings.initialScanBudget
        return CollectorIssue(
            path: url.path,
            reason: HealthMessages.directoryEnumerationLimitReached(
                maxEntries: budget.maxDirectoriesVisited,
                maxFiles: budget.maxFilesVisited
            )
        )
    }

    private func wallClockIssue(at url: URL) -> CollectorIssue {
        CollectorIssue(
            path: url.path,
            reason: HealthMessages.directoryEnumerationTimeLimitReached(
                seconds: settings.initialScanBudget.maxWallClockSeconds
            )
        )
    }
}
