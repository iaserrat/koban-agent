import Foundation

// MARK: - SurfaceSummaryFactory

struct SurfaceSummaryFactory {
    let freshnessPolicy: SurfaceFreshnessPolicy

    func summaries(
        for collectors: [any SurfaceCollector],
        using snapshot: PublishedStateSnapshot,
        queues: [SurfaceScanQueueState],
        now: Date
    ) -> [MonitoredSurface: SurfaceSummary] {
        var summaries: [MonitoredSurface: SurfaceSummary] = [:]
        let queueBySurface = Dictionary(uniqueKeysWithValues: queues.map { ($0.surface, $0) })
        for collector in collectors {
            let surface = collector.surface
            let surfaceHealth = snapshot.healthBySurface[surface]
            let queueState = queueBySurface[surface]
            let count = surfaceHealth?.itemCount ?? snapshot.itemCountsBySurface[surface] ?? 0
            let lastChange = snapshot.recentEvents.first { $0.surface == surface }?.timestamp
            summaries[surface] = SurfaceSummary(
                itemCount: count,
                lastChange: lastChange,
                healthState: freshnessPolicy.displayState(for: surfaceHealth, now: now),
                lastScanCompletedAt: surfaceHealth?.lastScanCompletedAt,
                lastFailure: surfaceHealth?.lastFailure,
                lastWatchIssue: surfaceHealth?.lastWatchIssue,
                lastWatchIssueAt: surfaceHealth?.lastWatchIssueAt,
                lastScanDurationMilliseconds: surfaceHealth?.lastScanDurationMilliseconds,
                lastScanTelemetry: surfaceHealth?.lastScanTelemetry ?? ScanTelemetry(itemCount: count),
                watchPathCount: surfaceHealth?.watchPathCount ?? 0,
                isScanRunning: queueState?.isRunning ?? false,
                hasPendingScan: queueState?.hasPendingScan ?? false,
                coalescedTriggerCount: queueState?.coalescedTriggerCount ?? 0
            )
        }
        return summaries
    }
}

// MARK: - SurfaceSummaryFactory + Live

extension SurfaceSummaryFactory {
    static func live(configuration: KobanConfiguration) -> Self {
        Self(
            freshnessPolicy: SurfaceFreshnessPolicy(
                maxAgeSeconds: configuration.watch.maxFreshScanAgeSeconds
            )
        )
    }
}
