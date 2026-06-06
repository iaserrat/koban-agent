import Foundation

struct MonitoringScanner {
    let configuration: KobanConfiguration
    let inventory: InventoryRepository
    let commits: ScanCommitStore
    let healthRecorder: ScanHealthRecorder
    let runtime: ScanRuntime

    init(
        configuration: KobanConfiguration,
        inventory: InventoryRepository,
        commits: ScanCommitStore,
        health: HealthStore,
        runtime: ScanRuntime = .live
    ) {
        self.init(
            configuration: configuration,
            inventory: inventory,
            commits: commits,
            healthRecorder: ScanHealthRecorder(health: health),
            runtime: runtime
        )
    }

    init(
        configuration: KobanConfiguration,
        inventory: InventoryRepository,
        commits: ScanCommitStore,
        healthRecorder: ScanHealthRecorder,
        runtime: ScanRuntime = .live
    ) {
        self.configuration = configuration
        self.inventory = inventory
        self.commits = commits
        self.healthRecorder = healthRecorder
        self.runtime = runtime
    }

    func establishBaseline(_ collector: any SurfaceCollector) async throws {
        let startedAt = runtime.now()
        try healthRecorder.markScanStarted(collector.surface, startedAt)
        do {
            let collected = try await snapshot(collector)
            let completedAt = runtime.now()
            let artifactTimestamp = runtime.now()
            let found = presentFindings(from: collected.items, timestamp: artifactTimestamp)
            try commits.commitBaseline(
                surface: collector.surface,
                items: collected.items,
                findings: found,
                issues: collected.issues,
                durationMilliseconds: durationMilliseconds(from: startedAt, to: completedAt),
                completedAt: completedAt
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try recordFailure(collector.surface, scanError: error)
            throw error
        }
    }

    func runPipeline(_ collector: any SurfaceCollector) async throws {
        let surface = collector.surface
        let startedAt = runtime.now()
        try healthRecorder.markScanStarted(surface, startedAt)
        do {
            let previous = try inventory.snapshot(for: surface)
            let collected = try await snapshot(collector)
            let current = collected.items
            let changes = InventoryDiffer.diff(previous: previous, current: current)
            let completedAt = runtime.now()
            let artifactTimestamp = runtime.now()
            let feed = events(from: changes, timestamp: artifactTimestamp)
            let found = changeFindings(from: changes, timestamp: artifactTimestamp)
            let presentFound = presentFindings(from: current, timestamp: artifactTimestamp)

            try commits.commitScan(ScanCommit(
                surface: surface,
                previous: previous,
                current: current,
                events: feed,
                findings: found,
                presentFindings: presentFound,
                issues: collected.issues,
                durationMilliseconds: durationMilliseconds(from: startedAt, to: completedAt),
                completedAt: completedAt
            ))
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try recordFailure(surface, scanError: error)
            throw error
        }
    }

    private func recordFailure(_ surface: MonitoredSurface, scanError: any Error) throws {
        do {
            try healthRecorder.markScanFailed(surface, scanError, runtime.now())
        } catch {
            throw ScanFailureRecordingError(scanError: scanError, healthError: error)
        }
    }

    private func snapshot(_ collector: any SurfaceCollector) async throws -> CollectorSnapshot {
        let timeoutSeconds = configuration.watch.maxScanWallClockSeconds
        return try await withThrowingTaskGroup(of: CollectorSnapshot.self) { group in
            group.addTask {
                try await collector.collect()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(timeoutSeconds))
                throw SurfaceScanTimeoutError(seconds: timeoutSeconds)
            }
            do {
                let snapshot = try await group.next() ?? CollectorSnapshot(items: [])
                group.cancelAll()
                return snapshot
            } catch {
                group.cancelAll()
                throw error
            }
        }
    }

    private func events(from changes: [InventoryChange], timestamp: Date) -> [ChangeEvent] {
        changes.map { ChangeEventFactory.event(from: $0, timestamp: timestamp, id: runtime.makeID()) }
    }

    private func changeFindings(from changes: [InventoryChange], timestamp: Date) -> [Finding] {
        HeuristicEngine.evaluateChanges(
            rules: configuration.rules,
            changes: changes,
            timestamp: timestamp,
            makeID: runtime.makeID
        )
    }

    private func presentFindings(from items: [InventoryItem], timestamp: Date) -> [Finding] {
        HeuristicEngine.evaluatePresentItems(
            rules: configuration.rules,
            items: items,
            timestamp: timestamp,
            makeID: runtime.makeID
        )
    }

    private func durationMilliseconds(from start: Date, to end: Date) -> Double {
        end.timeIntervalSince(start) * TimeConstants.millisecondsPerSecond
    }
}
