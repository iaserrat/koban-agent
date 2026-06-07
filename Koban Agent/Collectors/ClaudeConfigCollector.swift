import Foundation

// MARK: - ClaudeConfigCollector

/// Builds the Claude inventory by reading the MCP servers declared in `~/.claude.json` - both
/// user-scope and per-project. Each server becomes one `InventoryItem`. A missing config file
/// is normal and yields an empty snapshot.
struct ClaudeConfigCollector: SurfaceCollector {
    let surface = MonitoredSurface.claudeConfig
    let configURLs: [URL]
    let settingsURLs: [URL]
    let customizationDirectories: [ClaudeCustomizationDirectory]
    let instructionURLs: [URL]
    let pluginURLs: [URL]
    let includeHooks: Bool, includePlugins: Bool
    let fileValidator: AgentConfigFileValidator
    let customizationMaxEntries: Int

    init(
        configURL: URL,
        settingsURLs: [URL] = [],
        customizationDirectories: [ClaudeCustomizationDirectory] = [],
        instructionURLs: [URL] = [],
        pluginURLs: [URL] = [],
        includeHooks: Bool = true,
        includePlugins: Bool = true,
        fileValidator: AgentConfigFileValidator = AgentConfigFileValidator(),
        customizationMaxEntries: Int = ConfigurationDefaults.directoryListingMaxEntries
    ) {
        self.init(
            configURLs: [configURL],
            settingsURLs: settingsURLs,
            customizationDirectories: customizationDirectories,
            instructionURLs: instructionURLs,
            pluginURLs: pluginURLs,
            includeHooks: includeHooks,
            includePlugins: includePlugins,
            fileValidator: fileValidator,
            customizationMaxEntries: customizationMaxEntries
        )
    }

    init(
        configURLs: [URL],
        settingsURLs: [URL] = [],
        customizationDirectories: [ClaudeCustomizationDirectory] = [],
        instructionURLs: [URL] = [],
        pluginURLs: [URL] = [],
        includeHooks: Bool = true,
        includePlugins: Bool = true,
        fileValidator: AgentConfigFileValidator = AgentConfigFileValidator(),
        customizationMaxEntries: Int = ConfigurationDefaults.directoryListingMaxEntries
    ) {
        self.configURLs = configURLs
        self.settingsURLs = settingsURLs
        self.customizationDirectories = customizationDirectories
        self.instructionURLs = instructionURLs
        self.pluginURLs = pluginURLs
        self.includeHooks = includeHooks
        self.includePlugins = includePlugins
        self.fileValidator = fileValidator
        self.customizationMaxEntries = customizationMaxEntries
    }

    /// We watch the file path itself; atomic-replace edits that FSEvents coalesces are caught
    /// by the engine's safety-net poll.
    var watchPaths: [String] {
        (configURLs + settingsURLs + customizationDirectories.map(\.url) + instructionURLs + pluginURLs)
            .map(\.path)
    }

    func snapshot() async throws -> [InventoryItem] {
        try await collect().items
    }

    func collect() async throws -> CollectorSnapshot {
        let config = try configItems()
        let settings = try settingsItems()
        let customizations = try customizationItems()
        let instructions = instructionItems()
        let plugins = try pluginFileItems()
        let items = config.items
            + settings.items
            + customizations.items
            + instructions.items
            + plugins.items

        return CollectorSnapshot(
            items: items.sorted { $0.id < $1.id },
            issues: config.issues
                + settings.issues
                + customizations.issues
                + instructions.issues
                + plugins.issues
        )
    }
}

// MARK: - Private

extension ClaudeConfigCollector {
    private func configItems() throws -> (items: [InventoryItem], issues: [CollectorIssue]) {
        var inventoryItems: [InventoryItem] = []
        var issues: [CollectorIssue] = []
        for url in configURLs {
            try Task.checkCancellation()
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                try Task.checkCancellation()
                if let issue = try fileValidator.issueIfTooLarge(url) {
                    issues.append(issue)
                    continue
                }
                try Task.checkCancellation()
                let data = try Data(contentsOf: url)
                try Task.checkCancellation()
                let file = try JSONDecoder().decode(ClaudeConfigFile.self, from: data)
                try Task.checkCancellation()
                inventoryItems.append(contentsOf: items(from: file, url: url))
            } catch let error as CancellationError {
                throw error
            } catch {
                issues.append(CollectorIssue(path: url.path, reason: String(describing: error)))
            }
        }
        return (inventoryItems, issues)
    }

    /// User-scope servers first, then project-scope; the first occurrence of a name wins so a
    /// user-scope server is never shadowed by a project one.
    private func items(from file: ClaudeConfigFile, url: URL) -> [InventoryItem] {
        let projectServers = (file.projects ?? [:]).values.flatMap { Array($0.mcpServers ?? [:]) }
        let allServers = Array(file.mcpServers ?? [:]) + projectServers

        var seen: Set<String> = []
        var items: [InventoryItem] = []
        for (name, spec) in allServers {
            guard seen.contains(name) == false,
                  let item = item(name: name, spec: spec, url: url) else { continue }
            seen.insert(name)
            items.append(item)
        }
        return items.sorted { $0.name < $1.name }
    }

    private func item(name: String, spec: MCPServerSpec, url: URL) -> InventoryItem? {
        MCPInventoryMapper.inventoryItem(
            surface: surface,
            name: name,
            path: url.path,
            spec: spec
        )
    }

    private func settingsItems() throws -> (items: [InventoryItem], issues: [CollectorIssue]) {
        var result = (items: [InventoryItem](), issues: [CollectorIssue]())
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
                result.items.append(contentsOf: ClaudeSettingsInventoryMapper.items(
                    from: dictionary,
                    url: url,
                    hash: hash.detail,
                    includeHooks: includeHooks,
                    includePlugins: includePlugins
                ))
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

    private func instructionItems() -> (items: [InventoryItem], issues: [CollectorIssue]) {
        instructionURLs.reduce(into: (items: [InventoryItem](), issues: [CollectorIssue]())) { result, url in
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
            result.items.append(InventoryItem(
                surface: surface,
                kind: .instruction,
                name: url.lastPathComponent,
                path: url.path,
                provenance: Provenance(
                    origin: ClaudeConfigNames.instructionOrigin,
                    detail: hash.detail
                )
            ))
            if let issue = hash.issue {
                result.issues.append(issue)
            }
        }
    }
}
