import Observation

/// The single source of UI truth, owned by the app and updated by the engine. `@MainActor`
/// because every read happens during view rendering; `@Observable` so SwiftUI tracks exactly
/// the fields each view touches.
@MainActor
@Observable
final class AppState {
    private(set) var isMonitoring = false
    private(set) var summaries: [MonitoredSurface: SurfaceSummary] = [:]
    private(set) var recentEvents: [ChangeEvent] = []
    private(set) var findings: [Finding] = []
    private(set) var syncStatus: SyncStatus = .disabled
    private(set) var readModelError: String?

    /// Bumped on every publish so the extended window can re-query the database when the engine
    /// produces new data, keeping the open window as live as the panel.
    private(set) var revision = 0

    func setMonitoring(_ isMonitoring: Bool) {
        self.isMonitoring = isMonitoring
    }

    func refresh(
        summaries: [MonitoredSurface: SurfaceSummary],
        events: [ChangeEvent],
        findings: [Finding],
        syncStatus: SyncStatus = .disabled
    ) {
        self.summaries = summaries
        recentEvents = events
        self.findings = findings
        self.syncStatus = syncStatus
        readModelError = nil
        revision += 1
    }

    func recordReadModelFailure(_ message: String) {
        readModelError = message
        revision += 1
    }
}
