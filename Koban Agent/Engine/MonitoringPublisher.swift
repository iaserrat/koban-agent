import Foundation
import OSLog

// MARK: - MonitoringPublisher

struct MonitoringPublisher {
    let summaryFactory: SurfaceSummaryFactory
    let collectors: [any SurfaceCollector]
    let appState: AppState
    let snapshot: () throws -> PublishedStateSnapshot

    init(
        readModels: ReadModelStore,
        summaryFactory: SurfaceSummaryFactory,
        collectors: [any SurfaceCollector],
        appState: AppState
    ) {
        self.summaryFactory = summaryFactory
        self.collectors = collectors
        self.appState = appState
        snapshot = {
            try readModels.publishedState(
                eventLimit: FeedLimits.events,
                findingLimit: FeedLimits.findings
            )
        }
    }

    init(
        snapshot: @escaping () throws -> PublishedStateSnapshot,
        summaryFactory: SurfaceSummaryFactory,
        collectors: [any SurfaceCollector],
        appState: AppState
    ) {
        self.snapshot = snapshot
        self.summaryFactory = summaryFactory
        self.collectors = collectors
        self.appState = appState
    }

    func publish(queues: [SurfaceScanQueueState]) async {
        guard Task.isCancelled == false else { return }
        let snapshot: PublishedStateSnapshot
        do {
            snapshot = try self.snapshot()
        } catch {
            Log.engine.error("Publishing read model failed: \(error).")
            await appState.recordReadModelFailure(String(describing: error))
            return
        }
        let summaries = summaryFactory.summaries(
            for: collectors,
            using: snapshot,
            queues: queues,
            now: .now
        )
        guard Task.isCancelled == false else { return }
        await appState.refresh(
            summaries: summaries,
            events: snapshot.recentEvents,
            findings: snapshot.recentFindings
        )
    }
}
