import Foundation

/// A run of identical change events about the same item, collapsed into one row for the glance
/// panel. The window shows events raw; the panel groups them so a repeated launch reads as one
/// line with a count rather than a wall of duplicates. Pure: built from events, no IO.
struct EventGroup: Identifiable, Hashable {
    /// The most recent event in the group; supplies the row's display fields.
    let representative: ChangeEvent

    /// Every event in the group, newest first (includes `representative`).
    let occurrences: [ChangeEvent]

    /// Stable identity: same surface, kind, item, and detail is one group.
    var id: String {
        Self.key(representative)
    }

    var count: Int {
        occurrences.count
    }

    var lastSeen: Date {
        representative.timestamp
    }

    private static func key(_ event: ChangeEvent) -> String {
        "\(event.surface.rawValue)/\(event.kind.rawValue)/\(event.itemID)/\(event.detail)"
    }

    /// Collapses events into groups, preserving the input's order of first appearance. Callers
    /// pass events newest-first, so each group's first occurrence is also its most recent.
    static func grouped(_ events: [ChangeEvent]) -> [Self] {
        OrderedGrouping.grouped(events, by: key).map {
            Self(representative: $0[0], occurrences: $0)
        }
    }
}
