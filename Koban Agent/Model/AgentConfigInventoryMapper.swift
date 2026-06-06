import Foundation

/// Converts normalized agent configuration into inventory items consumed by diffing and rules.
enum AgentConfigInventoryMapper {
    static func inventoryItem(from item: AgentConfigItem) -> InventoryItem {
        InventoryItem(
            surface: item.surface,
            kind: item.kind,
            name: item.name,
            version: item.version,
            path: item.path,
            provenance: Provenance(origin: item.origin, detail: item.detail)
        )
    }
}
