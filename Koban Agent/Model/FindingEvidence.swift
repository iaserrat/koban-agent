import Foundation

/// The concrete on-disk facts that caused a finding, captured when the rule fired so the
/// detail view can show "why we flagged this, and exactly what tripped the rule" without
/// re-deriving anything. Provenance comes from the item; the matched field/value comes from
/// the rule that fired (see CLAUDE.md - signal is read from metadata, not kernel events).
struct FindingEvidence: Codable, Hashable {
    /// Absolute path the affected item was discovered at.
    var path: String

    /// The full inspected detail, e.g. an MCP server's command line or transport URL. `nil`
    /// when the surface exposes no such string (most Homebrew items).
    var detail: String?

    /// The item field the rule keyed on (a `RuleField`/`RuleFlag` raw value), and that field's
    /// value at the time. Both `nil` for rules that always fire regardless of field contents.
    var matchedField: String?
    var matchedValue: String?
}
