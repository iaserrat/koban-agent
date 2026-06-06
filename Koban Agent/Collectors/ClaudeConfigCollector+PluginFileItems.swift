import Foundation

extension ClaudeConfigCollector {
    func pluginFileItems() throws -> (items: [InventoryItem], issues: [CollectorIssue]) {
        var result = (items: [InventoryItem](), issues: [CollectorIssue]())
        for url in pluginURLs {
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
                let hash = AgentConfigFileHash.detail(for: url, validator: fileValidator)
                let items = ClaudePluginNameExtractor.names(from: object).map { name in
                    InventoryItem(
                        surface: surface,
                        kind: .plugin,
                        name: name,
                        path: url.path,
                        provenance: Provenance(origin: ClaudeConfigNames.pluginOrigin, detail: hash.detail)
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
}
