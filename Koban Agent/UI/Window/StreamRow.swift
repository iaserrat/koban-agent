import Foundation

/// One row in the monitor's stream table, projected from a `ChangeEvent`, `FindingGroup`, or
/// `InventoryItem` so the table renders a single uniform type across every scope. A column only
/// reads the fields its scope declares (`MonitorScope.columns`), so the unset fields for a scope
/// are simply never drawn.
struct StreamRow: Identifiable, Hashable {
    /// Unique within a scope's rows: the source record's id. Drives table selection.
    let id: String
    let timestamp: Date?
    let badge: StreamBadge
    let surface: MonitoredSurface
    let name: String
    let path: String?
    let detail: String?
    let version: String?
    let origin: String?

    /// The worst severity of any finding about this item, or `nil` when nothing flags it.
    let severity: Severity?

    /// Resolves back to the source record for the detail panel.
    let reference: StreamReference
}
