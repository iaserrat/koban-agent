import Testing
@testable import Koban_Agent

// MARK: - MonitoringStartupCoordinatorTests

struct MonitoringStartupCoordinatorTests {
    @Test
    func primesCollectorsConcurrently() async {
        let recorder = StartupPrimeRecorder()
        let primer = MonitoringPrimer(prime: { collector in
            await recorder.started(collector.surface)
            await recorder.waitUntilAllStarted()
            await recorder.finished(collector.surface)
        })
        let coordinator = MonitoringStartupCoordinator(primer: primer, scheduler: SurfaceScanScheduler())
        let collectors: [any SurfaceCollector] = [
            StartupCollector(surface: .homebrew),
            StartupCollector(surface: .claudeConfig)
        ]
        let expected = Set(collectors.map(\.surface))

        await coordinator.prime(collectors)

        let observed = await recorder.finishedSurfaces
        #expect(Set(observed) == expected)
    }

    @Test
    func reportsIndexingProgressForEverySurface() async {
        let recorder = IndexingProgressRecorder()
        let primer = MonitoringPrimer(prime: { _ in })
        let progress = IndexingProgress(
            willBegin: { await recorder.began($0) },
            willIndex: { await recorder.willIndex($0) },
            didIndex: { await recorder.didIndex($0) },
            didComplete: { await recorder.completed() }
        )
        let coordinator = MonitoringStartupCoordinator(
            primer: primer,
            scheduler: SurfaceScanScheduler(),
            progress: progress
        )
        let collectors: [any SurfaceCollector] = [
            StartupCollector(surface: .homebrew),
            StartupCollector(surface: .claudeConfig)
        ]
        let expected = Set(collectors.map(\.surface))

        await coordinator.prime(collectors)

        #expect(await recorder.begunSurfaces == expected)
        #expect(await Set(recorder.startedSurfaces) == expected)
        #expect(await Set(recorder.indexedSurfaces) == expected)
        #expect(await recorder.completedCount == 1)
    }

    @Test
    func cancelledPrimeSkipsCollectors() async {
        let recorder = StartupCancellationRecorder()
        let primer = MonitoringPrimer(prime: { collector in
            await recorder.primed(collector.surface)
        })
        let coordinator = MonitoringStartupCoordinator(primer: primer, scheduler: SurfaceScanScheduler())
        let collectors: [any SurfaceCollector] = [
            StartupCollector(surface: .homebrew),
            StartupCollector(surface: .claudeConfig)
        ]

        let task = Task {
            await coordinator.prime(collectors)
            return await recorder.primedSurfaces
        }
        task.cancel()

        let primedSurfaces = await task.value
        #expect(primedSurfaces.isEmpty)
    }
}

// MARK: - StartupCollector

private struct StartupCollector: SurfaceCollector {
    let surface: MonitoredSurface
    let watchPaths: [String] = []

    func snapshot() async throws -> [InventoryItem] {
        []
    }
}

// MARK: - StartupPrimeRecorder

private actor StartupPrimeRecorder {
    private static let expectedSurfaceCount = 2

    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var startedSurfaces: Set<MonitoredSurface> = []
    private(set) var finishedSurfaces: [MonitoredSurface] = []

    func started(_ surface: MonitoredSurface) {
        startedSurfaces.insert(surface)
        guard startedSurfaces.count == Self.expectedSurfaceCount else { return }
        let waiting = continuations
        continuations.removeAll()
        for continuation in waiting {
            continuation.resume()
        }
    }

    func waitUntilAllStarted() async {
        guard startedSurfaces.count < Self.expectedSurfaceCount else { return }
        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func finished(_ surface: MonitoredSurface) {
        finishedSurfaces.append(surface)
    }
}

// MARK: - IndexingProgressRecorder

private actor IndexingProgressRecorder {
    private(set) var begunSurfaces: Set<MonitoredSurface> = []
    private(set) var startedSurfaces: [MonitoredSurface] = []
    private(set) var indexedSurfaces: [MonitoredSurface] = []
    private(set) var completedCount = 0

    func began(_ surfaces: [MonitoredSurface]) {
        begunSurfaces = Set(surfaces)
    }

    func willIndex(_ surface: MonitoredSurface) {
        startedSurfaces.append(surface)
    }

    func didIndex(_ surface: MonitoredSurface) {
        indexedSurfaces.append(surface)
    }

    func completed() {
        completedCount += 1
    }
}

// MARK: - StartupCancellationRecorder

private actor StartupCancellationRecorder {
    private(set) var primedSurfaces: [MonitoredSurface] = []

    func primed(_ surface: MonitoredSurface) {
        primedSurfaces.append(surface)
    }
}
