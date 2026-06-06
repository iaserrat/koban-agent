import Foundation

extension ClaudeConfigCollector {
    func customizationItems() -> (items: [InventoryItem], issues: [CollectorIssue]) {
        customizationDirectories.reduce(
            into: (items: [InventoryItem](), issues: [CollectorIssue]())
        ) { result, directory in
            guard FileManager.default.fileExists(atPath: directory.url.path) else { return }
            var enumerationIssues: [CollectorIssue] = []
            guard let enumerator = FileManager.default.enumerator(
                at: directory.url,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants],
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
