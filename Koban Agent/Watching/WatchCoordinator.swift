import Foundation
import OSLog

/// `@unchecked Sendable` is justified: the only mutable state is `watcher`, and `start()`/
/// `stop()` are called solely from the owning `MonitoringEngine` actor, which serialises them.
/// The escaping closure handed to `FSEventsWatcher` captures only immutable values and the
/// internally-locked `WatchSignalDispatcher`, so it touches no unsynchronised state.
final class WatchCoordinator: @unchecked Sendable {
    private let plan: WatchPlan
    private let latency: TimeInterval
    private let dispatcher: WatchSignalDispatcher
    private var watcher: FSEventsWatcher?

    init(
        plan: WatchPlan,
        latency: TimeInterval,
        onSignal: @escaping @Sendable (WatchSignal) async -> Void
    ) {
        self.plan = plan
        self.latency = latency
        dispatcher = WatchSignalDispatcher(onSignal: onSignal)
    }

    @discardableResult
    func start() -> Bool {
        guard watcher == nil else { return true }
        guard plan.paths.isEmpty == false else { return false }

        let watcher = FSEventsWatcher(paths: plan.paths, latency: latency) { [plan, dispatcher] events in
            let signal = WatchSignal(events: events, plan: plan)
            guard signal.surfaces.isEmpty == false else { return }
            dispatcher.enqueue(signal)
        }
        guard watcher.start() else { return false }
        self.watcher = watcher
        let pathCount = plan.paths.count
        Log.watching.info("Watch coordinator started with \(pathCount) path(s).")
        return true
    }

    func stop() {
        dispatcher.cancel()
        watcher?.stop()
        watcher = nil
    }
}
