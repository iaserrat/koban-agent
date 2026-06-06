import Foundation

// MARK: - CodexConfigCollector

/// Builds Codex inventory from local user and project configuration files.
struct CodexConfigCollector: SurfaceCollector {
    let surface = MonitoredSurface.codexConfig
    let configURLs: [URL]
    let hooksURLs: [URL]
    let rulesDirectories: [URL]
    let skillsDirectories: [URL]
    let initialIssues: [CollectorIssue]
    let tomlReader: TOMLDocumentReader
    let fileValidator: AgentConfigFileValidator

    init(
        configURLs: [URL],
        hooksURLs: [URL],
        rulesDirectories: [URL],
        skillsDirectories: [URL],
        initialIssues: [CollectorIssue] = [],
        tomlReader: TOMLDocumentReader = TOMLDocumentReader(),
        fileValidator: AgentConfigFileValidator = AgentConfigFileValidator()
    ) {
        self.configURLs = configURLs
        self.hooksURLs = hooksURLs
        self.rulesDirectories = rulesDirectories
        self.skillsDirectories = skillsDirectories
        self.initialIssues = initialIssues
        self.tomlReader = tomlReader
        self.fileValidator = fileValidator
    }

    var watchPaths: [String] {
        (configURLs + hooksURLs + rulesDirectories + skillsDirectories).map(\.path)
    }

    func snapshot() async throws -> [InventoryItem] {
        try await collect().items
    }

    func collect() async throws -> CollectorSnapshot {
        let config = try configItems()
        let hooks = try hooksItems()
        let rules = try ruleItems()
        let skills = try skillItems()
        let agentItems = config.items
            + hooks.items
            + rules.items
            + skills.items
        return CollectorSnapshot(
            items: agentItems
                .map(AgentConfigInventoryMapper.inventoryItem(from:))
                .sorted { $0.id < $1.id },
            issues: initialIssues + config.issues + hooks.issues + rules.issues + skills.issues
        )
    }
}

// MARK: - Private

extension CodexConfigCollector {
    private func configItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        var result = (items: [AgentConfigItem](), issues: [CollectorIssue]())
        for url in configURLs {
            try Task.checkCancellation()
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                try Task.checkCancellation()
                if let issue = try fileValidator.issueIfTooLarge(url) {
                    result.issues.append(issue)
                    continue
                }
                try Task.checkCancellation()
                let text = try tomlReader.read(url)
                try Task.checkCancellation()
                let file = try tomlReader.decode(CodexConfigFile.self, from: text)
                try Task.checkCancellation()
                let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
                var items = [
                    AgentConfigItem(
                        surface: surface,
                        kind: .configProfile,
                        name: url.lastPathComponent,
                        path: url.path,
                        origin: HeuristicConstants.codexConfigOrigin,
                        detail: hash.detail
                    )
                ]
                items.append(contentsOf: mcpItems(from: file, url: url))
                items.append(contentsOf: inlineHookItems(from: text, url: url, hash: hash.detail))
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

    private func mcpItems(from file: CodexConfigFile, url: URL) -> [AgentConfigItem] {
        (file.mcpServers ?? [:]).compactMap { name, spec in
            MCPInventoryMapper.agentConfigItem(
                surface: surface,
                name: name,
                path: url.path,
                spec: spec
            )
        }
    }

    private func hooksItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        var result = (items: [AgentConfigItem](), issues: [CollectorIssue]())
        for url in hooksURLs {
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
                        kind: .hook,
                        name: key,
                        path: url.path,
                        origin: HeuristicConstants.codexHooksOrigin,
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

    private func inlineHookItems(from content: String, url: URL, hash: String?) -> [AgentConfigItem] {
        inlineHookNames(in: content).map { key in
            AgentConfigItem(
                surface: surface,
                kind: .hook,
                name: key,
                path: url.path,
                origin: HeuristicConstants.codexHooksOrigin,
                detail: hash
            )
        }
    }

    private func inlineHookNames(in content: String) -> [String] {
        let names = content
            .split(separator: "\n")
            .compactMap { line -> String? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix(CodexConfigNames.hookTablePrefix),
                      trimmed.hasSuffix(CodexConfigNames.tableSuffix)
                else { return nil }
                let withoutPrefix = trimmed.dropFirst(CodexConfigNames.hookTablePrefix.count)
                let name = withoutPrefix.dropLast(CodexConfigNames.tableSuffix.count)
                return name.isEmpty ? nil : String(name)
            }
        return Array(Set(names)).sorted()
    }

    private func ruleItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        try rulesDirectories.reduce(
            into: (items: [AgentConfigItem](), issues: [CollectorIssue]())
        ) { result, directory in
            let search = try AgentConfigFileFinder.files(
                in: directory,
                matching: KnownPaths.codexRuleFileExtension
            )
            result.issues.append(contentsOf: search.issues)
            for url in search.files {
                let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
                result.items.append(AgentConfigItem(
                    surface: surface,
                    kind: .rule,
                    name: url.lastPathComponent,
                    path: url.path,
                    origin: HeuristicConstants.codexRulesOrigin,
                    detail: hash.detail
                ))
                if let issue = hash.issue {
                    result.issues.append(issue)
                }
            }
        }
    }

    private func skillItems() throws -> (items: [AgentConfigItem], issues: [CollectorIssue]) {
        try skillsDirectories.reduce(
            into: (items: [AgentConfigItem](), issues: [CollectorIssue]())
        ) { result, directory in
            let search = try AgentConfigFileFinder.files(
                in: directory,
                named: KnownPaths.codexSkillFileName
            )
            result.issues.append(contentsOf: search.issues)
            for url in search.files {
                let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
                result.items.append(AgentConfigItem(
                    surface: surface,
                    kind: .skill,
                    name: url.deletingLastPathComponent().lastPathComponent,
                    path: url.path,
                    origin: HeuristicConstants.codexSkillsOrigin,
                    detail: hash.detail
                ))
                if let issue = hash.issue {
                    result.issues.append(issue)
                }
            }
        }
    }
}
