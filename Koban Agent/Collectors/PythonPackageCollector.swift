import Foundation

/// Builds Python package inventory from configured project metadata files.
struct PythonPackageCollector: SurfaceCollector {
    let surface = MonitoredSurface.pythonPackages
    let discoverer: ProjectFileDiscoverer
    let tomlReader: TOMLDocumentReader
    let fileValidator: PackageMetadataFileValidator
    let requirementParseBudget: PythonRequirementParseBudget

    init(
        discoverer: ProjectFileDiscoverer,
        tomlReader: TOMLDocumentReader = TOMLDocumentReader(),
        fileValidator: PackageMetadataFileValidator = PackageMetadataFileValidator(),
        requirementParseBudget: PythonRequirementParseBudget = .defaultValue
    ) {
        self.discoverer = discoverer
        self.tomlReader = tomlReader
        self.fileValidator = fileValidator
        self.requirementParseBudget = requirementParseBudget
    }

    var watchPaths: [String] {
        discoverer.rootPaths
    }

    func snapshot() async throws -> [InventoryItem] {
        try await collect().items
    }

    func collect() async throws -> CollectorSnapshot {
        let discovery = try discoverer.candidateFileResult()
        let parsed = records(from: discovery.files)
        let items = PackageInventoryMapper.inventoryItems(from: parsed.records, surface: surface)
        return CollectorSnapshot(items: items, issues: discovery.issues + parsed.issues)
    }

    private func records(
        from url: URL
    ) throws -> (records: [PackageInventoryRecord], issues: [CollectorIssue]) {
        switch url.lastPathComponent {
        case PackageMetadataNames.uvLockName:
            return try (uvRecords(from: url), [])
        case PackageMetadataNames.pyprojectName:
            return try (pyprojectRecords(from: url), [])
        case PackageMetadataNames.pylockName:
            return try (pylockRecords(from: url), [])
        default:
            let result = try requirementRecords(from: url)
            return (result.records, result.issues)
        }
    }

    private func records(from urls: [URL]) -> (records: [PackageInventoryRecord], issues: [CollectorIssue]) {
        urls.reduce(into: (records: [PackageInventoryRecord](), issues: [CollectorIssue]())) { result, url in
            do {
                if let issue = try fileValidator.issueIfTooLarge(url) {
                    result.issues.append(issue)
                    return
                }
                let parsed = try records(from: url)
                result.records.append(contentsOf: parsed.records)
                result.issues.append(contentsOf: parsed.issues)
            } catch {
                result.issues.append(CollectorIssue(path: url.path, reason: String(describing: error)))
            }
        }
    }

    private func uvRecords(from url: URL) throws -> [PackageInventoryRecord] {
        let file = try tomlReader.decode(UvLockfile.self, from: url)
        return (file.package ?? []).map {
            PackageInventoryRecord(
                name: $0.name,
                version: $0.version,
                manager: PackageMetadataNames.uvManager,
                detail: nil,
                path: url.path,
                kind: .pythonResolvedPackage
            )
        }
    }

    private func pylockRecords(from url: URL) throws -> [PackageInventoryRecord] {
        let file = try tomlReader.decode(UvLockfile.self, from: url)
        return (file.packages ?? []).map {
            PackageInventoryRecord(
                name: $0.name,
                version: $0.version,
                manager: PackageMetadataNames.pylockManager,
                detail: nil,
                path: url.path,
                kind: .pythonResolvedPackage
            )
        }
    }

    private func pyprojectRecords(from url: URL) throws -> [PackageInventoryRecord] {
        let file = try tomlReader.decode(PyProjectFile.self, from: url)
        return pyprojectRequirements(file)
            .compactMap { PythonRequirementParser().requirement(from: $0) }
            .map { name in
                PackageInventoryRecord(
                    name: name,
                    version: nil,
                    manager: PackageMetadataNames.pyprojectManager,
                    detail: nil,
                    path: url.path,
                    kind: .pythonDeclaredRequirement
                )
            }
    }

    private func pyprojectRequirements(_ file: PyProjectFile) -> [String] {
        var requirements = file.project?.dependencies ?? []
        requirements.append(contentsOf: (file.project?.optionalDependencies ?? [:]).values.flatMap(\.self))
        requirements.append(contentsOf: file.buildSystem?.requires ?? [])
        requirements.append(contentsOf: (file.dependencyGroups ?? [:]).values.flatMap(\.self))
        return requirements
    }

    private func requirementRecords(from url: URL) throws -> PythonRequirementParseResult {
        let isConstraint = url.lastPathComponent.hasPrefix(PackageMetadataNames.pythonConstraintsPrefix)
        let kind: InventoryKind = isConstraint ? .pythonConstraint : .pythonDeclaredRequirement
        return try PythonRequirementParser().result(
            from: url,
            kind: kind,
            validator: fileValidator,
            budget: requirementParseBudget
        )
    }
}
