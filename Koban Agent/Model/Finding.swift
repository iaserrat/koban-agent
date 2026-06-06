import Foundation

/// An indicator of compromise raised by a heuristic rule about an inventory item.
/// Findings are advisory - Koban surfaces them, it never blocks (see CLAUDE.md).
struct Finding: Codable, Hashable, Identifiable {
    var id: UUID
    var timestamp: Date
    var surface: MonitoredSurface

    /// The stable inventory item identity this finding belongs to.
    var itemID: InventoryItem.ID

    /// The rule that produced this finding (see `RuleID`).
    var ruleID: String

    /// Short headline, e.g. "New MCP server".
    var title: String

    /// Why this was flagged, in plain language.
    var rationale: String
    var severity: Severity

    /// The affected item's name.
    var itemName: String

    /// The concrete on-disk facts that triggered this finding, for the detail view.
    var evidence: FindingEvidence
}
