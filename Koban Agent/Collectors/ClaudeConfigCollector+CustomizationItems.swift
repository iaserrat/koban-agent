import Foundation

extension ClaudeConfigCollector {
    func customizationItems() throws -> (items: [InventoryItem], issues: [CollectorIssue]) {
        try customizationDirectories.reduce(
            into: (items: [InventoryItem](), issues: [CollectorIssue]())
        ) { result, directory in
            guard FileManager.default.fileExists(atPath: directory.url.path) else { return }
            // Skills use a directory-per-skill layout (`skills/<name>/SKILL.md`), so they are
            // discovered by searching for the receipt file.
            if directory.kind == .skill {
                try appendSkillItems(directory: directory, result: &result)
                return
            }
            var enumerationIssues: [CollectorIssue] = []
            guard let enumerator = FileManager.default.enumerator(
                at: directory.url,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                options: enumerationOptions(for: directory.kind),
                errorHandler: { url, error in
                    enumerationIssues.append(CollectorIssue(
                        path: url.path,
                        reason: String(describing: error)
                    ))
                    return true
                }
            ) else {
                result.issues.append(CollectorIssue(
                    path: directory.url.path,
                    reason: HealthMessages.directoryEnumerationUnavailable
                ))
                return
            }
            result.issues.append(contentsOf: enumerationIssues)

            appendCustomizationItems(
                from: enumerator,
                directory: directory,
                result: &result
            )
        }
    }

    /// Claude Code scans subagents recursively (they may be organized into subfolders), while
    /// commands are mapped by filename only and are not namespaced by subfolder.
    private func enumerationOptions(for kind: InventoryKind) -> FileManager.DirectoryEnumerationOptions {
        var options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
        if kind != .agent {
            options.insert(.skipsSubdirectoryDescendants)
        }
        return options
    }

    private func appendSkillItems(
        directory: ClaudeCustomizationDirectory,
        result: inout (items: [InventoryItem], issues: [CollectorIssue])
    ) throws {
        let search = try AgentConfigFileFinder.files(
            in: directory.url,
            named: KnownPaths.agentSkillFileName
        )
        result.issues.append(contentsOf: search.issues)
        for url in search.files {
            let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
            result.items.append(InventoryItem(
                surface: surface,
                kind: directory.kind,
                name: url.deletingLastPathComponent().lastPathComponent,
                path: url.path,
                provenance: Provenance(
                    origin: ClaudeConfigNames.customizationOrigin,
                    detail: hash.detail
                )
            ))
            if let issue = hash.issue {
                result.issues.append(issue)
            }
        }
    }

    private func appendCustomizationItems(
        from enumerator: FileManager.DirectoryEnumerator,
        directory: ClaudeCustomizationDirectory,
        result: inout (items: [InventoryItem], issues: [CollectorIssue])
    ) {
        var entriesVisited = 0
        for entry in enumerator {
            entriesVisited += 1
            guard entriesVisited <= customizationMaxEntries else {
                result.issues.append(CollectorIssue(
                    path: directory.url.path,
                    reason: HealthMessages.directoryEnumerationEntryLimitReached(
                        maxEntries: customizationMaxEntries
                    )
                ))
                break
            }
            guard let url = entry as? URL else { continue }
            let item = customizationItem(from: url, kind: directory.kind)
            if let inventoryItem = item.item {
                result.items.append(inventoryItem)
            }
            if let issue = item.issue {
                result.issues.append(issue)
            }
        }
    }

    private func customizationItem(
        from url: URL,
        kind: InventoryKind
    ) -> (item: InventoryItem?, issue: CollectorIssue?) {
        do {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            guard values.isDirectory != true else { return (nil, nil) }
            guard values.isRegularFile == true else {
                return (nil, CollectorIssue(path: url.path, reason: HealthMessages.fileIsNotRegular))
            }
            let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
            return (InventoryItem(
                surface: surface,
                kind: kind,
                name: url.lastPathComponent,
                path: url.path,
                provenance: Provenance(
                    origin: ClaudeConfigNames.customizationOrigin,
                    detail: hash.detail
                )
            ), hash.issue)
        } catch {
            return (nil, CollectorIssue(path: url.path, reason: String(describing: error)))
        }
    }
}
