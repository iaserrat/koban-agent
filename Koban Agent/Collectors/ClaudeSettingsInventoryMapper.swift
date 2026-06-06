import Foundation

enum ClaudeSettingsInventoryMapper {
    static func items(
        from dictionary: [String: Any],
        url: URL,
        hash: String?,
        includeHooks: Bool = true,
        includePlugins: Bool = true
    ) -> [InventoryItem] {
        var items = settingsItems(from: dictionary, url: url, hash: hash)
        if includeHooks {
            items.append(contentsOf: hookItems(from: dictionary, url: url, hash: hash))
        }
        items.append(contentsOf: permissionItems(from: dictionary, url: url, hash: hash))
        if includePlugins {
            items.append(contentsOf: pluginItems(from: dictionary, url: url, hash: hash))
        }
        return items
    }

    private static func settingsItems(
        from dictionary: [String: Any],
        url: URL,
        hash: String?
    ) -> [InventoryItem] {
        dictionary.keys.sorted().map { key in
            InventoryItem(
                surface: .claudeConfig,
                kind: .settings,
                name: key,
                path: url.path,
                provenance: Provenance(origin: ClaudeConfigNames.settingsOrigin, detail: hash)
            )
        }
    }

    private static func hookItems(
        from dictionary: [String: Any],
        url: URL,
        hash: String?
    ) -> [InventoryItem] {
        guard dictionary[ClaudeConfigNames.hooksKey] != nil else { return [] }
        return [
            InventoryItem(
                surface: .claudeConfig,
                kind: .hook,
                name: ClaudeConfigNames.hooksKey,
                path: url.path,
                provenance: Provenance(origin: ClaudeConfigNames.hookOrigin, detail: hash)
            )
        ]
    }

    private static func permissionItems(
        from dictionary: [String: Any],
        url: URL,
        hash: String?
    ) -> [InventoryItem] {
        guard let permissions = dictionary[ClaudeConfigNames.permissionsKey] as? [String: Any]
        else { return [] }
        var items: [InventoryItem] = []
        if permissions[ClaudeConfigNames.allowKey] != nil {
            items.append(permissionItem(name: ClaudeConfigNames.permissionAllowName, url: url, hash: hash))
        }
        if permissions[ClaudeConfigNames.denyKey] != nil {
            items.append(permissionItem(name: ClaudeConfigNames.permissionDenyName, url: url, hash: hash))
        }
        return items
    }

    private static func permissionItem(name: String, url: URL, hash: String?) -> InventoryItem {
        InventoryItem(
            surface: .claudeConfig,
            kind: .settings,
            name: name,
            path: url.path,
            provenance: Provenance(origin: ClaudeConfigNames.settingsOrigin, detail: hash)
        )
    }

    private static func pluginItems(
        from dictionary: [String: Any],
        url: URL,
        hash: String?
    ) -> [InventoryItem] {
        let keys = [
            ClaudeConfigNames.enabledPluginsKey,
            ClaudeConfigNames.extraKnownMarketplacesKey,
            ClaudeConfigNames.pluginMarketplacesKey,
            ClaudeConfigNames.pluginsKey
        ]
        // A plugin can be named under several keys at once; it is still one plugin, so the same
        // name at this path must not produce duplicate rows competing for the same identity.
        var seen = Set<String>()
        return keys
            .flatMap { ClaudePluginNameExtractor.names(from: dictionary[$0]) }
            .filter { seen.insert($0).inserted }
            .map { name in
                InventoryItem(
                    surface: .claudeConfig,
                    kind: .plugin,
                    name: name,
                    path: url.path,
                    provenance: Provenance(origin: ClaudeConfigNames.pluginOrigin, detail: hash)
                )
            }
    }
}
