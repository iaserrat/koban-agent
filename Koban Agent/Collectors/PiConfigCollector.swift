import Foundation

// MARK: - PiConfigCollector

/// Builds Pi inventory from shared and Pi-owned local configuration files.
struct PiConfigCollector: SurfaceCollector {
    let surface = MonitoredSurface.piConfig
    let mcpConfigURLs: [URL]
    let settingsURLs: [URL]
    let packageDirectories: [URL]
    let includeImports: Bool
    let jsonReader: JSONDocumentReader
    let fileValidator: AgentConfigFileValidator

    init(
        mcpConfigURLs: [URL],
        settingsURLs: [URL],
        packageDirectories: [URL],
        includeImports: Bool,
        jsonReader: JSONDocumentReader = JSONDocumentReader(),
        fileValidator: AgentConfigFileValidator = AgentConfigFileValidator()
    ) {
        self.mcpConfigURLs = mcpConfigURLs
        self.settingsURLs = settingsURLs
        self.packageDirectories = packageDirectories
        self.includeImports = includeImports
        self.jsonReader = jsonReader
        self.fileValidator = fileValidator
    }

    var watchPaths: [String] {
        (mcpConfigURLs + settingsURLs + packageDirectories).map(\.path)
    }

    func snapshot() async throws -> [InventoryItem] {
        try await collect().items
    }

    func collect() async throws -> CollectorSnapshot {
        let mcpConfig = try mcpConfigItems()
        let settings = try settingsItems()
        let packages = try packageItems()
        let agentItems = mcpConfig.items
            + settings.items
            + packages.items
        return CollectorSnapshot(
            items: agentItems
                .map(AgentConfigInventoryMapper.inventoryItem(from:))
                .sorted { $0.id < $1.id },
            issues: mcpConfig.issues + settings.issues + packages.issues
        )
    }
}

// MARK: - Private

extension PiConfigCollector {
    private func mcpConfigItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        var result = (items: [AgentConfigItem](), issues: [CollectorIssue]())
        for url in mcpConfigURLs {
            try Task.checkCancellation()
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                try Task.checkCancellation()
                if let issue = try fileValidator.issueIfTooLarge(url) {
                    result.issues.append(issue)
                    continue
                }
                try Task.checkCancellation()
                let file = try jsonReader.decode(PiConfigFile.self, from: url)
                try Task.checkCancellation()
                result.items.append(
                    contentsOf: mcpItems(from: file, url: url) + importItems(from: file, url: url)
                )
            } catch let error as CancellationError {
                throw error
            } catch {
                result.issues.append(CollectorIssue(path: url.path, reason: String(describing: error)))
            }
        }
        return result
    }

    private func mcpItems(from file: PiConfigFile, url: URL) -> [AgentConfigItem] {
        (file.mcpServers ?? [:]).compactMap { name, spec in
            MCPInventoryMapper.agentConfigItem(
                surface: surface,
                name: name,
                path: url.path,
                spec: spec
            )
        }
    }

    private func importItems(from file: PiConfigFile, url: URL) -> [AgentConfigItem] {
        guard includeImports else { return [] }
        return (file.imports ?? []).map { name in
            AgentConfigItem(
                surface: surface,
                kind: .import,
                name: name,
                path: url.path,
                origin: HeuristicConstants.piImportOrigin
            )
        }
    }

    private func settingsItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        var result = (items: [AgentConfigItem](), issues: [CollectorIssue]())
        for url in settingsURLs {
            try Task.checkCancellation()
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            do {
                try Task.checkCancellation()
                if let issue = try fileValidator.issueIfTooLarge(url) {
                    result.issues.append(issue)
                    continue
                }
                try Task.checkCancellation()
                let data = try Data(contentsOf: url)
                try Task.checkCancellation()
                let object = try JSONSerialization.jsonObject(with: data)
                try Task.checkCancellation()
                guard let dictionary = object as? [String: Any] else { continue }
                let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
                let items = dictionary.keys.sorted().map { key in
                    AgentConfigItem(
                        surface: surface,
                        kind: .settings,
                        name: key,
                        path: url.path,
                        origin: HeuristicConstants.piSettingsOrigin,
                        detail: hash.detail
                    )
                }
                result.items.append(contentsOf: items)
                if let issue = hash.issue {
                    result.issues.append(issue)
                }
            } catch let error as CancellationError {
                throw error
            } catch {
                result.issues.append(CollectorIssue(path: url.path, reason: String(describing: error)))
            }
        }
        return result
    }

    private func packageItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        try packageDirectories.reduce(
            into: (items: [AgentConfigItem](), issues: [CollectorIssue]())
        ) { result, directory in
            let search = try AgentConfigFileFinder.files(
                in: directory,
                named: KnownPaths.packageJSONName
            )
            result.issues.append(contentsOf: search.issues)
            for url in search.files {
                let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
                result.items.append(AgentConfigItem(
                    surface: surface,
                    kind: .plugin,
                    name: url.deletingLastPathComponent().lastPathComponent,
                    path: url.path,
                    origin: HeuristicConstants.piPackageOrigin,
                    detail: hash.detail
                ))
                if let issue = hash.issue {
                    result.issues.append(issue)
                }
            }
        }
    }
}
