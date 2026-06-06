import Foundation
import Testing
@testable import Koban_Agent

// MARK: - SurfaceScanSchedulerStressTests

/// Stress/load gate for `SurfaceScanScheduler` under simultaneous rescans.
///
/// Budgets are logical rather than timed (the charter forbids wall-clock dependence):
/// peak concurrent scans is bounded by the surface count, same-surface bursts collapse
/// to a single pending operation, and the queue-state structure never grows beyond one
/// entry per surface (the memory budget).
struct SurfaceScanSchedulerStressTests {
    private static let triggersPerSurface = 1000

    @Test
    func simultaneousRescansStayBoundedAndCoalescePerSurface() async {
        let scheduler = SurfaceScanScheduler()
        let probe = StressScanProbe()
        let surfaces = MonitoredSurface.allCases

        // Occupy every surface with a held scan.
        for surface in surfaces {
            await scheduler.schedule(surface) { await probe.run(surface) }
        }
        await probe.waitForStartedCount(surfaces.count)

        // Different surfaces progress concurrently: every surface is running at once.
        #expect(await probe.maxConcurrent == surfaces.count)
        #expect(await probe.perSurfaceMaxConcurrent == 1)

        // Slam each surface with a high-volume burst while it is busy.
        for _ in 0 ..< Self.triggersPerSurface {
            for surface in surfaces {
                await scheduler.schedule(surface) { await probe.run(surface) }
            }
        }

        // Same-surface work coalesces: one running, one pending, the rest collapsed into
        // the coalesced trigger count. Memory budget: one queue entry per surface.
        let backedUp = await scheduler.queueStates()
        #expect(backedUp.count == surfaces.count)
        for state in backedUp {
            #expect(state.isRunning)
            #expect(state.hasPendingScan)
            #expect(state.coalescedTriggerCount == Self.triggersPerSurface)
        }

        // Release the running scans: each surface runs its single coalesced pending scan.
        await probe.releaseAll()
        await probe.waitForStartedCount(surfaces.count * 2)
        await probe.releaseAll()

        // Despite triggersPerSurface * surfaces enqueues, only two scans ran per surface.
        #expect(await probe.startedCount == surfaces.count * 2)
        #expect(await probe.maxConcurrent == surfaces.count)
    }

    @Test
    func cancellationStormNeverClearsANewerRunningScan() async {
        let scheduler = SurfaceScanScheduler()
        let probe = StressScanProbe()

        // Repeatedly start a scan, cancel it mid-flight, then start a fresh one. A stale
        // cancelled scan's completion must never tear down the newer running scan. Each
        // iteration starts exactly one scan, so absolute counts stay in lockstep with it.
        let storm = 200
        for index in 1 ... storm {
            await scheduler.schedule(.homebrew) { await probe.runUntilCancelled() }
            await probe.waitForStartedCount(index)
            await scheduler.cancelAll()
            await probe.waitForCancelledCount(index)
        }

        // A final live scan must survive and complete normally.
        await scheduler.schedule(.homebrew) { await probe.run(.homebrew) }
        await probe.waitForStartedCount(storm + 1)
        let runningStates = await scheduler.queueStates()
        #expect(runningStates.count == 1)
        #expect(runningStates[0].isRunning)
        await probe.releaseAll()
        await probe.waitForDrainIdle()

        let idleStates = await scheduler.queueStates()
        #expect(idleStates.isEmpty)
    }
}

// MARK: - StressScanProbe

private actor StressScanProbe {
    private(set) var startedCount = 0
    private(set) var cancelledCount = 0
    private(set) var maxConcurrent = 0
    private(set) var perSurfaceMaxConcurrent = 0

    private var concurrent = 0
    private var perSurfaceConcurrent: [MonitoredSurface: Int] = [:]
    private var releaseContinuations: [CheckedContinuation<Void, Never>] = []
    private var startWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var cancelWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var idleWaiters: [CheckedContinuation<Void, Never>] = []

    func run(_ surface: MonitoredSurface) async {
        enter(surface)
        await withCheckedContinuation { continuation in
            releaseContinuations.append(continuation)
        }
        leave(surface)
    }

    func runUntilCancelled() async {
        enter(.homebrew)
        while Task.isCancelled == false {
            await Task.yield()
        }
        cancelledCount += 1
        resumeCancelWaiters()
        leave(.homebrew)
    }

    func waitForStartedCount(_ count: Int) async {
        guard startedCount < count else { return }
        await withCheckedContinuation { continuation in
            startWaiters.append((count, continuation))
        }
    }

    func waitForCancelledCount(_ count: Int) async {
        guard cancelledCount < count else { return }
        await withCheckedContinuation { continuation in
            cancelWaiters.append((count, continuation))
        }
    }

    func waitForDrainIdle() async {
        guard concurrent > 0 else { return }
        await withCheckedContinuation { continuation in
            idleWaiters.append(continuation)
        }
    }

    func releaseAll() {
        let continuations = releaseContinuations
        releaseContinuations.removeAll()
        for continuation in continuations {
            continuation.resume()
        }
    }

    private func enter(_ surface: MonitoredSurface) {
        startedCount += 1
        concurrent += 1
        maxConcurrent = max(maxConcurrent, concurrent)
        let surfaceCount = (perSurfaceConcurrent[surface] ?? 0) + 1
        perSurfaceConcurrent[surface] = surfaceCount
        perSurfaceMaxConcurrent = max(perSurfaceMaxConcurrent, surfaceCount)
        resumeStartWaiters()
    }

    private func leave(_ surface: MonitoredSurface) {
        concurrent -= 1
        perSurfaceConcurrent[surface] = (perSurfaceConcurrent[surface] ?? 1) - 1
        if concurrent == 0 {
            let waiters = idleWaiters
            idleWaiters.removeAll()
            for waiter in waiters {
                waiter.resume()
            }
        }
    }

    private func resumeStartWaiters() {
        let ready = startWaiters.filter { startedCount >= $0.0 }
        startWaiters.removeAll { startedCount >= $0.0 }
        for waiter in ready {
            waiter.1.resume()
        }
    }

    private func resumeCancelWaiters() {
        let ready = cancelWaiters.filter { cancelledCount >= $0.0 }
        cancelWaiters.removeAll { cancelledCount >= $0.0 }
        for waiter in ready {
            waiter.1.resume()
        }
    }
}
