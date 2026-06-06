import Foundation

actor SurfaceScanScheduler {
    private let makeID: @Sendable () -> UUID

    private var running: [MonitoredSurface: Task<Void, Never>] = [:]
    private var scanIDs: [MonitoredSurface: UUID] = [:]
    private var pending: Set<MonitoredSurface> = []
    private var pendingOperations: [MonitoredSurface: PendingSurfaceScanOperation] = [:]
    private var coalescedTriggerCounts: [MonitoredSurface: Int] = [:]

    init(makeID: @escaping @Sendable () -> UUID = ScanRuntime.live.makeID) {
        self.makeID = makeID
    }

    @discardableResult
    func schedule(
        _ surface: MonitoredSurface,
        operation: @escaping @Sendable () async -> Void
    ) -> SurfaceScanScheduleResult {
        schedule(surface, operation: PendingSurfaceScanOperation(run: operation))
    }

    private func schedule(
        _ surface: MonitoredSurface,
        operation: PendingSurfaceScanOperation
    ) -> SurfaceScanScheduleResult {
        if running[surface] != nil {
            pending.insert(surface)
            let discardedOperation = pendingOperations.updateValue(operation, forKey: surface)
            discardedOperation?.discard()
            let coalescedTriggerCount = (coalescedTriggerCounts[surface] ?? 0) + 1
            coalescedTriggerCounts[surface] = coalescedTriggerCount
            return .coalesced(coalescedTriggerCount: coalescedTriggerCount)
        }

        start(surface, operation: operation)
        return .started
    }

    @discardableResult
    func scheduleAndWait(
        _ surface: MonitoredSurface,
        operation: @escaping @Sendable () async -> Void
    ) async -> SurfaceScanScheduleResult {
        var scheduledResult: SurfaceScanScheduleResult = .started
        await withCheckedContinuation { continuation in
            scheduledResult = schedule(
                surface,
                operation: PendingSurfaceScanOperation(
                    run: {
                        await operation()
                        continuation.resume()
                    },
                    discard: {
                        continuation.resume()
                    }
                )
            )
        }
        return scheduledResult
    }

    func cancelAll() {
        let discardedOperations = pendingOperations.values
        pending.removeAll()
        pendingOperations.removeAll()
        coalescedTriggerCounts.removeAll()
        let tasks = running.values
        running.removeAll()
        scanIDs.removeAll()
        for task in tasks {
            task.cancel()
        }
        for operation in discardedOperations {
            operation.discard()
        }
    }

    func queueStates() -> [SurfaceScanQueueState] {
        let surfaces = Set(running.keys)
            .union(pending)
            .union(coalescedTriggerCounts.keys)

        return surfaces
            .sorted { $0.rawValue < $1.rawValue }
            .map { surface in
                SurfaceScanQueueState(
                    surface: surface,
                    isRunning: running[surface] != nil,
                    runningScanID: scanIDs[surface],
                    hasPendingScan: pending.contains(surface),
                    coalescedTriggerCount: coalescedTriggerCounts[surface] ?? 0
                )
            }
    }

    private func start(
        _ surface: MonitoredSurface,
        operation: PendingSurfaceScanOperation
    ) {
        let scanID = makeID()
        scanIDs[surface] = scanID
        running[surface] = Task {
            await operation.run()
            await finish(surface, scanID: scanID, operation: operation)
        }
    }

    private func finish(
        _ surface: MonitoredSurface,
        scanID: UUID,
        operation: PendingSurfaceScanOperation
    ) async {
        guard scanIDs[surface] == scanID else { return }
        if pending.remove(surface) != nil {
            coalescedTriggerCounts[surface] = nil
            let nextOperation = pendingOperations.removeValue(forKey: surface) ?? operation
            start(surface, operation: nextOperation)
        } else {
            running[surface] = nil
            scanIDs[surface] = nil
            pendingOperations[surface] = nil
            coalescedTriggerCounts[surface] = nil
        }
    }
}
