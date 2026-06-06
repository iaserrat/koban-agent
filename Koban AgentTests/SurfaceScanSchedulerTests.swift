import Foundation
import Testing
@testable import Koban_Agent

// MARK: - SurfaceScanSchedulerTests

struct SurfaceScanSchedulerTests {
    @Test
    func coalescesRepeatedSignalsWhileSurfaceIsRunning() async throws {
        let scanID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000101"))
        let scheduler = SurfaceScanScheduler(makeID: { scanID })
        let probe = ScanProbe()

        await scheduler.schedule(.homebrew) {
            await probe.run()
        }
        await probe.waitForStartedCount(1)

        await scheduler.schedule(.homebrew) {
            await probe.run()
        }
        let secondResult = await scheduler.schedule(.homebrew) {
            await probe.run()
        }
        let statesWhileBackedUp = await scheduler.queueStates()

        #expect(secondResult == .coalesced(coalescedTriggerCount: 2))
        #expect(statesWhileBackedUp == [
            SurfaceScanQueueState(
                surface: .homebrew,
                isRunning: true,
                runningScanID: scanID,
                hasPendingScan: true,
                coalescedTriggerCount: 2
            )
        ])

        await probe.finishNext()
        await probe.waitForStartedCount(2)
        let statesWhilePendingScanRuns = await scheduler.queueStates()
        #expect(statesWhilePendingScanRuns == [
            SurfaceScanQueueState(
                surface: .homebrew,
                isRunning: true,
                runningScanID: scanID,
                hasPendingScan: false,
                coalescedTriggerCount: 0
            )
        ])
        await probe.finishNext()

        let count = await probe.startedCount
        #expect(count == 2)
    }

    @Test
    func runsDifferentSurfacesConcurrently() async {
        let scheduler = SurfaceScanScheduler()
        let probe = ScanProbe()

        await scheduler.schedule(.homebrew) {
            await probe.run()
        }
        await scheduler.schedule(.codexConfig) {
            await probe.run()
        }

        await probe.waitForStartedCount(2)

        let count = await probe.startedCount
        #expect(count == 2)

        await probe.finishNext()
        await probe.finishNext()
    }

    @Test
    func cancelAllCancelsRunningScanAndDropsPendingScan() async {
        let scheduler = SurfaceScanScheduler()
        let probe = ScanProbe()

        await scheduler.schedule(.homebrew) {
            await probe.runUntilCancelled()
        }
        await probe.waitForStartedCount(1)

        await scheduler.schedule(.homebrew) {
            await probe.run()
        }

        await scheduler.cancelAll()
        await probe.waitForCancelledCount(1)

        let count = await probe.startedCount
        #expect(count == 1)
    }

    @Test
    func cancelledScanCannotClearNewerRunningScan() async {
        let scheduler = SurfaceScanScheduler()
        let probe = ScanProbe()

        await scheduler.schedule(.homebrew) {
            await probe.runUntilCancelledThenWait()
        }
        await probe.waitForStartedCount(1)
        await scheduler.cancelAll()
        await probe.waitForCancelledCount(1)

        await scheduler.schedule(.homebrew) {
            await probe.run()
        }
        await probe.waitForStartedCount(2)
        await probe.finishNext()

        await scheduler.schedule(.homebrew) {
            await probe.run()
        }
        await Task.yield()

        let countBeforeCurrentScanFinishes = await probe.startedCount
        #expect(countBeforeCurrentScanFinishes == 2)

        await probe.finishNext()
        await probe.waitForStartedCount(3)
        await probe.finishNext()
    }
}

// MARK: - ScanProbe

private actor ScanProbe {
    private(set) var startedCount = 0
    private(set) var cancelledCount = 0
    private var finishContinuations: [CheckedContinuation<Void, Never>] = []
    private var startWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var cancelWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

    func run() async {
        startedCount += 1
        resumeSatisfiedStartWaiters()
        await withCheckedContinuation { continuation in
            finishContinuations.append(continuation)
        }
    }

    func runUntilCancelled() async {
        startedCount += 1
        resumeSatisfiedStartWaiters()
        while Task.isCancelled == false {
            await Task.yield()
        }
        cancelledCount += 1
        resumeSatisfiedCancelWaiters()
    }

    func runUntilCancelledThenWait() async {
        await runUntilCancelled()
        await withCheckedContinuation { continuation in
            finishContinuations.append(continuation)
        }
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

    func finishNext() {
        guard finishContinuations.isEmpty == false else { return }
        finishContinuations.removeFirst().resume()
    }

    private func resumeSatisfiedStartWaiters() {
        let ready = startWaiters.filter { startedCount >= $0.0 }
        startWaiters.removeAll { startedCount >= $0.0 }
        for waiter in ready {
            waiter.1.resume()
        }
    }

    private func resumeSatisfiedCancelWaiters() {
        let ready = cancelWaiters.filter { cancelledCount >= $0.0 }
        cancelWaiters.removeAll { cancelledCount >= $0.0 }
        for waiter in ready {
            waiter.1.resume()
        }
    }
}
