import Foundation
import OSLog

// MARK: - MonitoringEngine

/// The orchestrator. It owns the monitoring lifecycle, runs the snapshot pipeline, and publishes
/// results to `AppState`. An actor because it is the one place mutable monitoring state lives;
/// everything it calls into is either pure or a value-typed repository.
actor MonitoringEngine {
    private let configuration: KobanConfiguration
    private let startup: MonitoringStartupCoordinator
    private let poller: MonitoringPoller
    private let syncPoller: SyncPoller
    private let lifecycle: MonitoringLifecycleGate
    private let scanScheduler: SurfaceScanScheduler
    private let publishScheduler: PublishScheduler
    private let publisher: MonitoringPublisher
    private let scanner: MonitoringScanner
    private let syncUploader: SyncUploader
    private let health: HealthStore
    private let watchHealth: WatchHealthRecorder
    private let shutdown: MonitoringShutdownCoordinator
    private let collectors: [any SurfaceCollector]
    private let appState: AppState
    private let remoteConfigUpdateHandler: (@Sendable () async -> Void)?
    private let now: @Sendable () -> Date

    private var watchCoordinator: WatchCoordinator?
    private var debouncers: [MonitoredSurface: WatchDebouncer] = [:]

    init(
        configuration: KobanConfiguration,
        database: AppDatabase,
        appState: AppState,
        remoteConfigUpdateHandler: (@Sendable () async -> Void)? = nil,
        indexingProgress: IndexingProgress = .silent,
        runtime: ScanRuntime = .live
    ) throws {
        self.configuration = configuration
        shutdown = MonitoringShutdownCoordinator(database: database)
        self.appState = appState
        self.remoteConfigUpdateHandler = remoteConfigUpdateHandler
        let madeCollectors = try CollectorFactory.make(for: configuration)
        let inventory = InventoryRepository(database: database)
        let healthStore = HealthStore(database: database)
        let commits = Self.makeCommitStore(database: database, configuration: configuration)
        let monitoringScanner = MonitoringScanner(
            configuration: configuration,
            inventory: inventory,
            commits: commits,
            health: healthStore,
            runtime: runtime
        )
        poller = MonitoringPoller(
            interval: .seconds(configuration.watch.pollIntervalSeconds),
            surfaces: madeCollectors.map(\.surface)
        )
        syncPoller = SyncPoller(interval: .seconds(configuration.sync.checkInIntervalSeconds))
        syncUploader = SyncUploader(store: SyncOutboxStore(database: database))
        lifecycle = MonitoringLifecycleGate(makeID: runtime.makeID)
        scanScheduler = SurfaceScanScheduler(makeID: runtime.makeID)
        publishScheduler = PublishScheduler()
        scanner = monitoringScanner
        now = runtime.now
        startup = MonitoringStartupCoordinator(
            primer: MonitoringPrimer(inventory: inventory, scanner: monitoringScanner),
            scheduler: scanScheduler,
            progress: indexingProgress
        )
        health = healthStore
        watchHealth = WatchHealthRecorder(health: healthStore, now: runtime.now)
        collectors = madeCollectors
        publisher = MonitoringPublisher(
            readModels: ReadModelStore(database: database),
            summaryFactory: SurfaceSummaryFactory.live(configuration: configuration),
            collectors: madeCollectors,
            appState: appState
        )
    }

    /// Establishes (or catches up) each surface, starts watching, and begins polling.
    func start() async {
        let generation = await lifecycle.start()
        setUpWatching(generation: generation)
        await poller.start { [weak self] surface in
            await self?.rescan(surface, generation: generation)
        }
        await startup.prime(collectors)
        guard await lifecycle.isActive(generation) else { return }
        await startSync(generation: generation)
        await appState.setMonitoring(true)
        await requestPublish(generation: generation)
    }

    func stop() async {
        await lifecycle.stop()
        await poller.stop()
        await syncPoller.stop()
        watchCoordinator?.stop()
        watchCoordinator = nil
        let cancelling = debouncers.values
        debouncers.removeAll()
        for debouncer in cancelling {
            await debouncer.cancel()
        }
        await scanScheduler.cancelAll()
        await publishScheduler.cancel()
        shutdown.checkpointDatabase()
        await appState.setMonitoring(false)
    }

    /// Re-scans one surface in response to a watch trigger or the poll, then publishes.
    func rescan(_ surface: MonitoredSurface) async {
        guard let generation = await lifecycle.current() else { return }
        await rescan(surface, generation: generation)
    }

    private func rescan(_ surface: MonitoredSurface, generation: UUID) async {
        guard await lifecycle.isActive(generation) else { return }
        let result = await scanScheduler.schedule(surface) { [weak self] in
            await self?.runScheduledScan(surface, generation: generation)
        }
        if case .coalesced = result { await requestPublish(generation: generation) }
    }

    private func runScheduledScan(_ surface: MonitoredSurface, generation: UUID) async {
        guard await lifecycle.isActive(generation) else { return }
        guard let collector = collectors.first(where: { $0.surface == surface }) else { return }
        do {
            try await scanner.runPipeline(collector)
        } catch {
            Log.engine.error("Rescan of \(surface.rawValue, privacy: .public) failed: \(error).")
        }
        await requestPublish(generation: generation)
    }
}

// MARK: - Construction

extension MonitoringEngine {
    private static func makeCommitStore(
        database: AppDatabase,
        configuration: KobanConfiguration
    ) -> ScanCommitStore {
        ScanCommitStore(
            database: database,
            retention: StorageRetentionPolicy(settings: configuration.persistence),
            syncSettings: configuration.sync
        )
    }
}

// MARK: - Watching

extension MonitoringEngine {
    private func setUpWatching(generation: UUID) {
        let delay: Duration = .milliseconds(configuration.watch.debounceMilliseconds)
        for collector in collectors {
            let surface = collector.surface
            let debouncer = WatchDebouncer(delay: delay) { [weak self] in
                await self?.rescan(surface, generation: generation)
            }
            debouncers[surface] = debouncer
        }

        let setup = MonitoringWatchSetup(
            configuration: configuration,
            collectors: collectors,
            health: health,
            watchHealth: watchHealth
        )
        do {
            let plan = try setup.makePlan()
            watchCoordinator = setup.start(plan: plan) { [weak self] signal in
                await self?.signal(signal, generation: generation)
            }
        } catch is CancellationError {
            return
        } catch {
            Log.engine.error("Home signal watch planning failed: \(error).")
        }
    }

    private func signal(_ signal: WatchSignal, generation: UUID) async {
        guard await lifecycle.isActive(generation) else { return }
        if let degradationReason = signal.degradationReason {
            watchHealth.markDegraded(signal.surfaces, reason: degradationReason)
        }
        for surface in signal.surfaces {
            await debouncers[surface]?.signal()
        }
    }
}

// MARK: - Publishing

extension MonitoringEngine {
    private func publish(generation: UUID) async {
        guard await lifecycle.isActive(generation) else { return }
        let queues = await scanScheduler.queueStates()
        await publisher.publish(queues: queues)
    }

    private func requestPublish(generation: UUID) async {
        guard await lifecycle.isActive(generation) else { return }
        await publishScheduler.schedule { [weak self] in await self?.publish(generation: generation) }
    }
}

// MARK: - Sync

extension MonitoringEngine {
    private func startSync(generation: UUID) async {
        guard configuration.sync.enabled else { return }
        await syncPoller.start { [weak self] in
            await self?.syncOnce(generation: generation)
        }
    }

    private func syncOnce(generation: UUID) async {
        guard await lifecycle.isActive(generation) else { return }
        do {
            let result = try await syncUploader.uploadOnce(settings: configuration.sync, now: now())
            if result.fullResnapshotRequested {
                await rescanAll(generation: generation)
            }
            if result.configUpdateAvailable {
                Log.sync.info("Remote configuration update is available; restarting monitoring.")
                await remoteConfigUpdateHandler?()
            }
        } catch {
            Log.sync.error("Sensor sync failed: \(error).")
        }
    }

    private func rescanAll(generation: UUID) async {
        for collector in collectors {
            await rescan(collector.surface, generation: generation)
        }
    }
}
