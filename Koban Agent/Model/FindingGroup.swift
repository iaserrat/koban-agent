import Foundation

/// A set of findings that are the same indicator about the same item, collapsed into one row.
/// Grouping keeps the UI calm when one condition recurs (e.g. an ephemeral runner launching
/// repeatedly): the occurrence count itself becomes the signal. Pure: built from findings, no IO.
struct FindingGroup: Identifiable, Hashable {
    /// The most recent finding in the group; supplies the row's display fields.
    let representative: Finding

    /// Every finding in the group, newest first (includes `representative`).
    let occurrences: [Finding]

    /// Stable across snapshots: the same indicator about the same item is one group.
    var id: String {
        Self.key(representative)
    }

    var count: Int {
        occurrences.count
    }

    var lastSeen: Date {
        representative.timestamp
    }

    var firstSeen: Date {
        occurrences.last?.timestamp ?? representative.timestamp
    }

    private static func key(_ finding: Finding) -> String {
        "\(finding.surface.rawValue)/\(finding.ruleID)/\(finding.itemID)"
    }

    /// Collapses findings into groups, preserving the input's order of first appearance. Callers
    /// pass findings newest-first, so each group's first occurrence is also its most recent.
    static func grouped(_ findings: [Finding]) -> [Self] {
        OrderedGrouping.grouped(findings, by: key).map {
            Self(representative: $0[0], occurrences: $0)
        }
    }
}
