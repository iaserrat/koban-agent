import Foundation

// MARK: - MonitorRowBuilder

/// Projects the window's loaded data into the stream table's rows for a given scope, then applies
/// the surface filter and the search text. Pure: it takes the data in and returns rows out, with no
/// IO or clock, so the whole monitor's filtering behaviour is unit-testable (see CLAUDE.md).
enum MonitorRowBuilder {
    static func rows(
        scope: MonitorScope,
        data: MonitorData,
        surfaceFilter: MonitoredSurface?,
        searchText: String
    ) -> [StreamRow] {
        let severityByItem = severityByItemID(data.findingGroups)
        let itemsByID = index(data.inventories)
        let projected = project(
            scope: scope, data: data, severityByItem: severityByItem, itemsByID: itemsByID
        )
        let needle = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return projected.filter { row in
            (surfaceFilter == nil || row.surface == surfaceFilter) && matches(row, needle)
        }
    }

    /// The worst severity raised against each item, so an activity or inventory row can flag itself
    /// from the findings without re-walking them per row.
    static func severityByItemID(_ groups: [FindingGroup]) -> [InventoryItem.ID: Severity] {
        var result: [InventoryItem.ID: Severity] = [:]
        for group in groups {
            let finding = group.representative
            let worst = result[finding.itemID].map { max($0, finding.severity) }
            result[finding.itemID] = worst ?? finding.severity
        }
        return result
    }
}

// MARK: - Projection

extension MonitorRowBuilder {
    private static func project(
        scope: MonitorScope,
        data: MonitorData,
        severityByItem: [InventoryItem.ID: Severity],
        itemsByID: [InventoryItem.ID: InventoryItem]
    ) -> [StreamRow] {
        switch scope {
        case .home: []
        case .activity: activityRows(data.activity, severityByItem, itemsByID)
        case .findings: findingRows(data.findingGroups, itemsByID)
        case .inventory: inventoryRows(data.inventories, severityByItem)
        }
    }

    private static func activityRows(
        _ activity: [ChangeEvent],
        _ severityByItem: [InventoryItem.ID: Severity],
        _ itemsByID: [InventoryItem.ID: InventoryItem]
    ) -> [StreamRow] {
        activity.map { event in
            let item = itemsByID[event.itemID]
            return StreamRow(
                id: event.id.uuidString,
                timestamp: event.timestamp,
                badge: .change(event.kind),
                surface: event.surface,
                name: event.itemName,
                path: item?.path,
                detail: event.detail,
                version: item?.version,
                origin: item?.provenance.origin,
                severity: severityByItem[event.itemID],
                reference: .item(event.itemID, event.surface)
            )
        }
    }

    private static func findingRows(
        _ groups: [FindingGroup],
        _ itemsByID: [InventoryItem.ID: InventoryItem]
    ) -> [StreamRow] {
        groups.map { group in
            let finding = group.representative
            let item = itemsByID[finding.itemID]
            return StreamRow(
                id: group.id,
                timestamp: finding.timestamp,
                badge: .rule(finding.title),
                surface: finding.surface,
                name: finding.itemName,
                path: item?.path,
                detail: finding.rationale,
                version: item?.version,
                origin: item?.provenance.origin,
                severity: finding.severity,
                reference: .finding(group.id)
            )
        }
    }

    private static func inventoryRows(
        _ inventories: [MonitoredSurface: [InventoryItem]],
        _ severityByItem: [InventoryItem.ID: Severity]
    ) -> [StreamRow] {
        inventories
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .flatMap { surface, items in
                items.map { item in
                    StreamRow(
                        id: item.id,
                        timestamp: nil,
                        badge: .blank,
                        surface: surface,
                        name: item.name,
                        path: item.path,
                        detail: item.provenance.detail,
                        version: item.version,
                        origin: item.provenance.origin,
                        severity: severityByItem[item.id],
                        reference: .item(item.id, surface)
                    )
                }
            }
    }

    private static func index(
        _ inventories: [MonitoredSurface: [InventoryItem]]
    ) -> [InventoryItem.ID: InventoryItem] {
        var result: [InventoryItem.ID: InventoryItem] = [:]
        for items in inventories.values {
            for item in items {
                result[item.id] = item
            }
        }
        return result
    }

    private static func matches(_ row: StreamRow, _ needle: String) -> Bool {
        guard needle.isEmpty == false else { return true }
        return row.name.lowercased().contains(needle)
            || (row.path?.lowercased().contains(needle) ?? false)
    }
}
