import Foundation

/// Builds JavaScript package inventory from configured project lockfiles.
struct JavaScriptPackageCollector: SurfaceCollector {
    let surface = MonitoredSurface.javascriptPackages
    let discoverer: ProjectFileDiscoverer
    let fileValidator: PackageMetadataFileValidator

    init(
        discoverer: ProjectFileDiscoverer,
        fileValidator: PackageMetadataFileValidator = PackageMetadataFileValidator()
    ) {
        self.discoverer = discoverer
        self.fileValidator = fileValidator
    }

    var watchPaths: [String] {
        discoverer.rootPaths
    }

    func snapshot() async throws -> [InventoryItem] {
        try await collect().items
    }

    func collect() async throws -> CollectorSnapshot {
        let discovery = try candidateFileResult()
        let parsed = records(from: discovery.files)
        let items = PackageInventoryMapper.inventoryItems(from: parsed.records, surface: surface)
        return CollectorSnapshot(items: items, issues: discovery.issues + parsed.issues)
    }

    private func candidateFileResult() throws -> ProjectFileDiscoveryResult {
        var result = try discoverer.candidateFileResult()
        let shrinkwrapDirectories = Set(
            result.files
                .filter { $0.lastPathComponent == PackageMetadataNames.npmShrinkwrapName }
                .map { $0.deletingLastPathComponent() }
        )
        result.files = result.files.filter {
            $0.lastPathComponent != PackageMetadataNames.packageLockName
                || shrinkwrapDirectories.contains($0.deletingLastPathComponent()) == false
        }
        return result
    }

    private func records(from url: URL) throws -> [PackageInventoryRecord] {
        switch url.lastPathComponent {
        case PackageMetadataNames.packageLockName:
            try NpmLockfileParser().records(from: url, manager: PackageMetadataNames.npmManager)
        case PackageMetadataNames.npmShrinkwrapName:
            try NpmLockfileParser().records(from: url, manager: PackageMetadataNames.npmManager)
        case PackageMetadataNames.pnpmLockName:
            try PnpmLockfileParser().records(from: url)
        case PackageMetadataNames.yarnLockName:
            try YarnLockfileParser().records(from: url)
        case PackageMetadataNames.bunLockName:
            try BunLockfileParser().records(from: url)
        default:
            []
        }
    }

    private func records(from urls: [URL]) -> (records: [PackageInventoryRecord], issues: [CollectorIssue]) {
        urls.reduce(into: (records: [PackageInventoryRecord](), issues: [CollectorIssue]())) { result, url in
            do {
                if let issue = try fileValidator.issueIfTooLarge(url) {
                    result.issues.append(issue)
                    return
                }
                let parsedRecords = try records(from: url)
                result.records.append(contentsOf: parsedRecords)
            } catch {
                result.issues.append(CollectorIssue(path: url.path, reason: String(describing: error)))
            }
        }
    }
}
