import Foundation

/// Builds Cursor inventory from documented MCP and rules configuration files.
struct CursorConfigCollector: SurfaceCollector {
    let surface = MonitoredSurface.cursorConfig
    let mcpConfigURLs: [URL]
    let rulesDirectories: [URL]
    let legacyRuleURLs: [URL]
    let instructionURLs: [URL]
    let fileValidator: AgentConfigFileValidator

    init(
        mcpConfigURLs: [URL],
        rulesDirectories: [URL],
        legacyRuleURLs: [URL],
        instructionURLs: [URL],
        fileValidator: AgentConfigFileValidator = AgentConfigFileValidator()
    ) {
        self.mcpConfigURLs = mcpConfigURLs
        self.rulesDirectories = rulesDirectories
        self.legacyRuleURLs = legacyRuleURLs
        self.instructionURLs = instructionURLs
        self.fileValidator = fileValidator
    }

    var watchPaths: [String] {
        (mcpConfigURLs + rulesDirectories + legacyRuleURLs + instructionURLs).map(\.path)
    }

    func snapshot() async throws -> [InventoryItem] {
        try await collect().items
    }

    func collect() async throws -> CollectorSnapshot {
        let mcp = try mcpItems()
        let rules = try ruleItems()
        let legacyRules = legacyRuleItems()
        let instructions = instructionItems()
        let agentItems = mcp.items
            + rules.items
            + legacyRules.items
            + instructions.items
        return CollectorSnapshot(
            items: agentItems
                .map(AgentConfigInventoryMapper.inventoryItem(from:))
                .sorted { $0.id < $1.id },
            issues: mcp.issues + rules.issues + legacyRules.issues + instructions.issues
        )
    }

    private func mcpItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
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
                let data = try Data(contentsOf: url)
                try Task.checkCancellation()
                let file = try JSONDecoder().decode(ClaudeConfigFile.self, from: data)
                let items = (file.mcpServers ?? [:]).compactMap { name, spec in
                    MCPInventoryMapper.agentConfigItem(
                        surface: surface,
                        name: name,
                        path: url.path,
                        spec: spec
                    )
                }
                result.items.append(contentsOf: items)
            } catch let error as CancellationError {
                throw error
            } catch {
                result.issues.append(CollectorIssue(path: url.path, reason: String(describing: error)))
            }
        }
        return result
    }

    private func ruleItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        try rulesDirectories.reduce(
            into: (items: [AgentConfigItem](), issues: [CollectorIssue]())
        ) { result, directory in
            let search = try AgentConfigFileFinder.files(
                in: directory,
                matching: KnownPaths.cursorRuleFileExtension
            )
            result.issues.append(contentsOf: search.issues)
            for url in search.files {
                let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
                result.items.append(AgentConfigItem(
                    surface: surface,
                    kind: .rule,
                    name: url.lastPathComponent,
                    path: url.path,
                    origin: HeuristicConstants.cursorRulesOrigin,
                    detail: hash.detail
                ))
                if let issue = hash.issue {
                    result.issues.append(issue)
                }
            }
        }
    }

    private func legacyRuleItems() -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        legacyRuleURLs.reduce(into: (items: [AgentConfigItem](), issues: [CollectorIssue]())) { result, url in
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
            result.items.append(AgentConfigItem(
                surface: surface,
                kind: .rule,
                name: url.lastPathComponent,
                path: url.path,
                origin: HeuristicConstants.cursorLegacyRulesOrigin,
                detail: hash.detail
            ))
            if let issue = hash.issue {
                result.issues.append(issue)
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
                origin: HeuristicConstants.cursorInstructionOrigin,
                detail: hash.detail
            ))
            if let issue = hash.issue {
                result.issues.append(issue)
            }
        }
    }
}
