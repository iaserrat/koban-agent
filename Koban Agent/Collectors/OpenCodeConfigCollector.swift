import Foundation

// MARK: - OpenCodeConfigCollector

/// Builds OpenCode inventory from local global and project configuration directories.
struct OpenCodeConfigCollector: SurfaceCollector {
    let surface = MonitoredSurface.opencodeConfig
    let configURLs: [URL]
    let agentDirectories: [URL]
    let commandDirectories: [URL]
    let pluginDirectories: [URL]
    let instructionURLs: [URL]
    let includeMCP: Bool
    let jsonReader: JSONDocumentReader
    let fileValidator: AgentConfigFileValidator

    init(
        configURLs: [URL],
        agentDirectories: [URL],
        commandDirectories: [URL],
        pluginDirectories: [URL],
        instructionURLs: [URL],
        includeMCP: Bool = true,
        jsonReader: JSONDocumentReader = JSONDocumentReader(),
        fileValidator: AgentConfigFileValidator = AgentConfigFileValidator()
    ) {
        self.configURLs = configURLs
        self.agentDirectories = agentDirectories
        self.commandDirectories = commandDirectories
        self.pluginDirectories = pluginDirectories
        self.instructionURLs = instructionURLs
        self.includeMCP = includeMCP
        self.jsonReader = jsonReader
        self.fileValidator = fileValidator
    }

    var watchPaths: [String] {
        (configURLs + agentDirectories + commandDirectories + pluginDirectories + instructionURLs)
            .map(\.path)
    }

    func snapshot() async throws -> [InventoryItem] {
        try await collect().items
    }

    func collect() async throws -> CollectorSnapshot {
        let config = try configItems()
        let agents = try customizationItems(
            in: agentDirectories,
            kind: .agent,
            origin: HeuristicConstants.openCodeAgentOrigin
        )
        let commands = try customizationItems(
            in: commandDirectories,
            kind: .command,
            origin: HeuristicConstants.openCodeCommandOrigin
        )
        let plugins = try customizationItems(
            in: pluginDirectories,
            kind: .plugin,
            origin: HeuristicConstants.openCodePluginOrigin
        )
        let instructions = instructionItems()
        let agentItems = config.items
            + agents.items
            + commands.items
            + plugins.items
            + instructions.items
        return CollectorSnapshot(
            items: agentItems
                .map(AgentConfigInventoryMapper.inventoryItem(from:))
                .sorted { $0.id < $1.id },
            issues: config.issues
                + agents.issues
                + commands.issues
                + plugins.issues
                + instructions.issues
        )
    }
}

// MARK: - Private

extension OpenCodeConfigCollector {
    private func configItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        var result = (items: [AgentConfigItem](), issues: [CollectorIssue]())
        for url in configURLs {
            try Task.checkCancellation()
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                let sizeIssue = try fileValidator.issueIfTooLarge(url)
                let hash = configProfileHash(for: url, sizeIssue: sizeIssue)
                result.items.append(configProfileItem(for: url, hash: hash.detail))
                if let issue = hash.issue {
                    result.issues.append(issue)
                }
                guard sizeIssue == nil else { continue }
                guard KnownPaths.openCodeConfigNames.contains(url.lastPathComponent) else { continue }
                try result.items.append(contentsOf: decodedConfigItems(from: url, hash: hash.detail))
            } catch let error as CancellationError {
                throw error
            } catch {
                result.issues.append(CollectorIssue(path: url.path, reason: String(describing: error)))
            }
        }
        return result
    }

    private func configProfileHash(
        for url: URL,
        sizeIssue: CollectorIssue?
    ) -> (detail: String?, issue: CollectorIssue?) {
        sizeIssue == nil
            ? AgentConfigFileHash.detail(for: url, validator: fileValidator)
            : (detail: nil, issue: sizeIssue)
    }

    private func configProfileItem(for url: URL, hash: String?) -> AgentConfigItem {
        AgentConfigItem(
            surface: surface,
            kind: .configProfile,
            name: url.lastPathComponent,
            path: url.path,
            origin: HeuristicConstants.openCodeConfigOrigin,
            detail: hash
        )
    }

    private func decodedConfigItems(from url: URL, hash: String?) throws -> [AgentConfigItem] {
        try Task.checkCancellation()
        let file = try jsonReader.decode(OpenCodeConfigFile.self, from: url)
        try Task.checkCancellation()
        return mcpItems(from: file, url: url) + pluginItems(
            from: file,
            url: url,
            hash: hash
        )
    }

    private func mcpItems(from file: OpenCodeConfigFile, url: URL) -> [AgentConfigItem] {
        guard includeMCP else { return [] }
        return (file.mcp ?? [:]).compactMap { name, spec in
            MCPInventoryMapper.agentConfigItem(
                surface: surface,
                name: name,
                path: url.path,
                spec: spec
            )
        }
    }

    private func pluginItems(
        from file: OpenCodeConfigFile,
        url: URL,
        hash: String?
    ) -> [AgentConfigItem] {
        (file.plugin ?? []).map { name in
            AgentConfigItem(
                surface: surface,
                kind: .plugin,
                name: name,
                path: url.path,
                origin: HeuristicConstants.openCodePluginOrigin,
                detail: hash
            )
        }
    }

    private func customizationItems(
        in directories: [URL],
        kind: InventoryKind,
        origin: String
    ) throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        try directories.reduce(
            into: (items: [AgentConfigItem](), issues: [CollectorIssue]())
        ) { result, directory in
            let search = try AgentConfigFileFinder.files(
                in: directory,
                matching: KnownPaths.markdownFileExtension
            )
            result.issues.append(contentsOf: search.issues)
            for url in search.files {
                let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
                result.items.append(AgentConfigItem(
                    surface: surface,
                    kind: kind,
                    name: url.lastPathComponent,
                    path: url.path,
                    origin: origin,
                    detail: hash.detail
                ))
                if let issue = hash.issue {
                    result.issues.append(issue)
                }
            }
        }
    }

    private func instructionItems() -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        instructionURLs.reduce(
            into: (items: [AgentConfigItem](), issues: [CollectorIssue]())
        ) { result, url in
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
            result.items.append(AgentConfigItem(
                surface: surface,
                kind: .instruction,
                name: url.lastPathComponent,
                path: url.path,
                origin: HeuristicConstants.openCodeInstructionOrigin,
                detail: hash.detail
            ))
            if let issue = hash.issue {
                result.issues.append(issue)
            }
        }
    }
}
