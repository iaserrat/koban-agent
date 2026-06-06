import Foundation

/// A recorded change to the inventory, produced by diffing two snapshots. This is the
/// raw activity feed; heuristics decide separately whether a change is also a finding.
struct ChangeEvent: Codable, Hashable, Identifiable {
    var id: UUID
    var timestamp: Date
    var surface: MonitoredSurface
    var kind: ChangeKind

    /// Stable identity of the affected inventory item.
    var itemID: InventoryItem.ID

    /// The affected item's name.
    var itemName: String

    /// A short human-facing description, e.g. "1.2.3 -> 1.2.4" or "added from homebrew/core".
    var detail: String
}
