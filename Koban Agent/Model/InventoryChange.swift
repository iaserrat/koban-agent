import Foundation

/// A semantic change between two snapshots: the affected item and how it changed. This is the
/// shared output of diffing, consumed by both the activity feed (`ChangeEvent`) and the
/// heuristic engine (`Finding`). Carries no timestamp or identity, so diffing stays pure.
struct InventoryChange: Hashable {
    var kind: ChangeKind

    /// The current item for `.added`/`.modified`; the now-gone item for `.removed`.
    var item: InventoryItem

    /// The prior item, set only for `.modified`.
    var previous: InventoryItem?
}
