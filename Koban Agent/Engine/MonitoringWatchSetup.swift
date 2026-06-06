import Foundation
import OSLog

struct MonitoringWatchSetup {
    let configuration: KobanConfiguration
    let collectors: [any SurfaceCollector]
    let health: HealthStore
    let watchHealth: WatchHealthRecorder

    func makePlan() throws -> WatchPlan {
        let collectorSurfaces = Set(collectors.map(\.surface))
        let homeSignalPlan = try HomeSignalWatchPlanner().plan(
            settings: configuration.watch.homeSignalScan,
            enabledSurfaces: collectorSurfaces
        )
        watchHealth.markHomeSignalDiscoveryIssues(collectorSurfaces, issues: homeSignalPlan.issues)
        let interests = collectors.map {
            WatchInterest(surface: $0.surface, paths: $0.watchPaths)
        } + homeSignalPlan.interests
        let plan = WatchPlanCompiler().compile(interests: interests)
        record(plan)
        return plan
    }

    func start(
        plan: WatchPlan,
        signal: @escaping @Sendable (WatchSignal) async -> Void
    ) -> WatchCoordinator? {
        let coordinator = WatchCoordinator(plan: plan, latency: latency, onSignal: signal)
        guard coordinator.start() else {
            watchHealth.markUnavailable(plan)
            return nil
        }
        return coordinator
    }

    private var latency: TimeInterval {
        let milliseconds = TimeInterval(configuration.watch.debounceMilliseconds)
        return milliseconds / TimeConstants.millisecondsPerSecond
    }

    private func record(_ plan: WatchPlan) {
        do {
            try health.recordWatchPlan(plan)
        } catch {
            Log.engine.error("Recording watch plan health failed: \(error).")
        }
    }
}
