import Observation

/// The monitor window's view state and the panel's deep-link target in one. The glance panel writes
/// an intent here (a scope, a surface, a specific finding) and opens the window; the window reads
/// scope, filters, and selection to drive the stream table. Kept apart from `WindowDataModel`
/// (which owns the data) so navigation intent has one clear owner, the role the old sidebar router
/// played before the window became a single filtered table.
@MainActor
@Observable
final class MonitorModel {
    /// The scope the window opens on when nothing deep-links it elsewhere. Deep links
    /// (`show(scope:)`, `show(surface:)`, `show(finding:)`) override this.
    var scope: MonitorScope = .inventory
    var surfaceFilter: MonitoredSurface?
    var searchText: String = ""
    var selection: StreamRow.ID?

    /// Whether the window is showing the Settings page instead of the monitor stream. The toolbar's
    /// gear toggles this; it is window-only state, not a deep-link target.
    var isShowingSettings = false

    /// Switch to a scope with no surface filter and a cleared selection.
    func show(scope: MonitorScope) {
        self.scope = scope
        surfaceFilter = nil
        selection = nil
        isShowingSettings = false
    }

    /// Deep-link to one surface's inventory (the panel's surface rows land here).
    func show(surface: MonitoredSurface) {
        scope = .inventory
        surfaceFilter = surface
        selection = nil
        isShowingSettings = false
    }

    /// Deep-link straight to a finding: the group id is also its row id in the findings scope.
    func show(finding id: FindingGroup.ID) {
        scope = .findings
        surfaceFilter = nil
        selection = id
        isShowingSettings = false
    }
}
