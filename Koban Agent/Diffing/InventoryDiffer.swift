import Foundation

/// Compares two inventory snapshots and reports what changed. Pure and deterministic: no IO,
/// no clock, no identity - so it is trivially testable (see CLAUDE.md). Callers turn the
/// returned changes into timestamped `ChangeEvent`s and `Finding`s.
enum InventoryDiffer {
    /// One `InventoryChange` per added, removed, or modified item, in a stable order
    /// (added, then removed, then modified - each sorted by item id).
    static func diff(previous: [InventoryItem], current: [InventoryItem]) -> [InventoryChange] {
        let previousByID = index(previous)
        let currentByID = index(current)

        let added = current
            .filter { previousByID[$0.id] == nil }
            .sorted { $0.id < $1.id }
            .map { InventoryChange(kind: .added, item: $0, previous: nil) }

        let removed = previous
            .filter { currentByID[$0.id] == nil }
            .sorted { $0.id < $1.id }
            .map { InventoryChange(kind: .removed, item: $0, previous: nil) }

        let modified = current
            .sorted { $0.id < $1.id }
            .compactMap { item -> InventoryChange? in
                guard let old = previousByID[item.id], old != item else { return nil }
                return InventoryChange(kind: .modified, item: item, previous: old)
            }

        return added + removed + modified
    }

    private static func index(_ items: [InventoryItem]) -> [String: InventoryItem] {
        Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
