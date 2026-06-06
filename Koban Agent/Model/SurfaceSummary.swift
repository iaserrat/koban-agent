import Foundation

/// The at-a-glance state of one surface, shown as a row in the menu-bar popover.
struct SurfaceSummary: Hashable {
    var itemCount: Int
    var lastChange: Date?
    var healthState: SurfaceHealthState = .idle
    var lastScanCompletedAt: Date?
    var lastFailure: String?
    var lastWatchIssue: String?
    var lastWatchIssueAt: Date?
    var lastScanDurationMilliseconds: Double?
    var lastScanTelemetry = ScanTelemetry()
    var watchPathCount: Int = 0
    var isScanRunning: Bool = false
    var hasPendingScan: Bool = false
    var coalescedTriggerCount: Int = 0
}
