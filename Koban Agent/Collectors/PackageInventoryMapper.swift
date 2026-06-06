import Foundation

/// Converts package metadata into inventory items.
enum PackageInventoryMapper {
    /// Maps records to items sorted by id, keeping one item per identity. A lockfile or manifest
    /// can name the same package twice (the same dependency in several pyproject sections, a
    /// repeated lockfile key), and a snapshot must never list one item twice or the differ
    /// reports phantom changes when the duplicates' order shifts between scans.
    static func inventoryItems(
        from records: [PackageInventoryRecord],
        surface: MonitoredSurface
    ) -> [InventoryItem] {
        var seen = Set<String>()
        return records
            .map { inventoryItem(from: $0, surface: surface) }
            .sorted { $0.id < $1.id }
            .filter { seen.insert($0.id).inserted }
    }

    static func inventoryItem(
        from record: PackageInventoryRecord,
        surface: MonitoredSurface
    ) -> InventoryItem {
        InventoryItem(
            surface: surface,
            kind: record.kind,
            name: record.name,
            version: record.version,
            path: record.path,
            provenance: Provenance(origin: record.manager, detail: record.detail)
        )
    }
}
