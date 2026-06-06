import Foundation

/// The monitor window's top-level view: which stream the table shows. This replaces the old
/// sidebar's sections - the same dense table re-queries itself per scope rather than each scope
/// owning a separate column layout.
enum MonitorScope: String, CaseIterable, Identifiable {
    case home
    case inventory
    case activity
    case findings

    var id: String {
        rawValue
    }

    /// Whether this scope draws the dense stream table. The home dashboard is a bespoke overview, so
    /// it has no table, count, or search; the other scopes share the one filtered table.
    var usesStreamTable: Bool {
        self != .home
    }

    /// The section bar's heading for this scope.
    var title: String {
        switch self {
        case .home: "Overview"
        case .activity: "All activity"
        case .findings: "Findings"
        case .inventory: "Inventory"
        }
    }

    /// What the toolbar counts ("142 changes"), pluralised by the caller against the row count.
    var noun: String {
        switch self {
        case .home: ""
        case .activity: "changes"
        case .findings: "findings"
        case .inventory: "items"
        }
    }

    /// The toolbar's tab label.
    var label: String {
        switch self {
        case .home: "Overview"
        case .activity: "Activity"
        case .findings: "Findings"
        case .inventory: "Inventory"
        }
    }

    /// The ordered columns the table draws in this scope. Exactly one column is flexible (`width`
    /// nil) and absorbs the remaining width; the rest are fixed from `Metrics`. The home dashboard
    /// draws no table, so it has no columns.
    var columns: [StreamColumn] {
        switch self {
        case .home:
            []
        case .activity:
            [
                StreamColumn(kind: .time, title: "Time", width: Metrics.streamTimeWidth),
                StreamColumn(kind: .event, title: "Event", width: Metrics.streamEventWidth),
                StreamColumn(kind: .surface, title: "Surface", width: Metrics.streamSurfaceWidth),
                StreamColumn(kind: .context, title: "Context", width: nil),
                StreamColumn(kind: .detail, title: "Detail", width: Metrics.streamDetailWidth),
                StreamColumn(kind: .flag, title: "", width: Metrics.streamFlagWidth)
            ]
        case .findings:
            [
                StreamColumn(kind: .time, title: "Time", width: Metrics.streamTimeWidth),
                StreamColumn(kind: .event, title: "Rule", width: Metrics.streamEventWidth),
                StreamColumn(kind: .surface, title: "Surface", width: Metrics.streamSurfaceWidth),
                StreamColumn(kind: .context, title: "Item", width: nil),
                StreamColumn(kind: .severity, title: "Severity", width: Metrics.streamSeverityWidth),
                StreamColumn(kind: .flag, title: "", width: Metrics.streamFlagWidth)
            ]
        case .inventory:
            [
                StreamColumn(kind: .surface, title: "Surface", width: Metrics.streamSurfaceWidth),
                StreamColumn(kind: .context, title: "Name", width: nil),
                StreamColumn(kind: .version, title: "Version", width: Metrics.streamVersionWidth),
                StreamColumn(kind: .origin, title: "Origin", width: Metrics.streamOriginWidth),
                StreamColumn(kind: .flag, title: "", width: Metrics.streamFlagWidth)
            ]
        }
    }
}
