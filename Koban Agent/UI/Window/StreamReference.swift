import Foundation

/// Ties a selected `StreamRow` back to the source record so the detail panel can resolve full
/// provenance. Activity and inventory rows point at their affected item; findings rows point at
/// their group.
enum StreamReference: Hashable {
    case item(InventoryItem.ID, MonitoredSurface)
    case finding(FindingGroup.ID)
}
