import Foundation

// MARK: - SystemStatus

/// The single birds-eye verdict the home dashboard's header renders: the fusion of monitoring health
/// and the worst open finding into one answer to "is anything wrong right now?".
///
/// Health gates the verdict. A degraded agent can never claim all-clear, because a stopped watcher
/// can no longer vouch for what it is not seeing, and Koban's whole product is that visibility (see
/// CLAUDE.md). So the order is: a broken read model first, then "not yet watching", then degraded
/// monitoring, then findings, and only a live, healthy, unflagged agent reads as all clear.
enum SystemStatus: Equatable {
    /// The read model could not be loaded; the dashboard is holding the last known view.
    case dataUnavailable
    /// Monitoring has not produced a first full picture yet (launching, or the first scan is still
    /// running).
    case starting
    /// Monitoring itself is degraded (a watcher stopped). This outranks findings: trust the rest of
    /// the dashboard only once the agent is healthy again.
    case degraded
    /// One or more open findings, carrying the worst severity among them.
    case findings(Severity)
    /// Monitoring is live and healthy with nothing flagged.
    case allClear
}

extension SystemStatus {
    /// Resolves the verdict from the orthogonal signals the UI holds. Pure: the same inputs always
    /// produce the same verdict, so the priority order is unit-tested without any view or clock.
    static func evaluate(
        readModelFailed: Bool,
        isMonitoring: Bool,
        hasCompletedInitialScan: Bool,
        overallHealth: SurfaceHealthState,
        worstFindingSeverity: Severity?
    ) -> SystemStatus {
        if readModelFailed { return .dataUnavailable }
        guard isMonitoring, hasCompletedInitialScan else { return .starting }
        if overallHealth == .degraded { return .degraded }
        if let worstFindingSeverity { return .findings(worstFindingSeverity) }
        return .allClear
    }
}
