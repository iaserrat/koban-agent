import Foundation

/// Turns a pure `InventoryChange` into a timestamped, identified `ChangeEvent` for the
/// activity feed. Identity and time are injected so callers stay in control (and tests stay
/// deterministic).
enum ChangeEventFactory {
    static func event(from change: InventoryChange, timestamp: Date, id: UUID) -> ChangeEvent {
        ChangeEvent(
            id: id,
            timestamp: timestamp,
            surface: change.item.surface,
            kind: change.kind,
            itemID: change.item.id,
            itemName: change.item.name,
            detail: detail(for: change)
        )
    }

    private static func detail(for change: InventoryChange) -> String {
        switch change.kind {
        case .added, .removed:
            change.item.provenance.origin
        case .modified:
            VersionChange.describe(from: change.previous ?? change.item, to: change.item)
        }
    }
}
