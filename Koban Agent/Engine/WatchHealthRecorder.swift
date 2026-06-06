import Foundation
import OSLog

struct WatchHealthRecorder {
    let health: HealthStore
    let now: @Sendable () -> Date

    func markUnavailable(_ plan: WatchPlan) {
        markDegraded(
            Set(plan.interests.map(\.surface)),
            reason: HealthMessages.watchStreamUnavailable
        )
    }

    func markHomeSignalDiscoveryIssues(_ surfaces: Set<MonitoredSurface>, issues: [CollectorIssue]) {
        guard surfaces.isEmpty == false, issues.isEmpty == false else { return }
        markDegraded(
            surfaces,
            reason: HealthMessages.homeSignalDiscoveryIssues(
                count: issues.count,
                firstIssue: issues.first
            )
        )
    }

    func markDegraded(_ surfaces: Set<MonitoredSurface>, reason: String) {
        let date = now()
        for surface in surfaces {
            do {
                try health.markWatchDegraded(surface, reason: reason, at: date)
            } catch {
                Log.engine.error("Recording degraded watch health failed: \(error).")
            }
        }
    }
}
