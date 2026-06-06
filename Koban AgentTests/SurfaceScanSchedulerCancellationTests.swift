import Testing
@testable import Koban_Agent

// MARK: - SurfaceScanSchedulerCancellationTests

struct SurfaceScanSchedulerCancellationTests {
    @Test
    func cancelAllResumesCoalescedScheduleAndWait() async {
        let scheduler = SurfaceScanScheduler()
        let probe = CancellableScanProbe()
        let recorder = ScheduleResultRecorder()

        await scheduler.schedule(.homebrew) {
            await probe.runUntilCancelled()
        }
        await probe.waitForStartedCount(1)

        let waitTask = Task {
            let result = await scheduler.scheduleAndWait(.homebrew) {
                await probe.runUntilCancelled()
            }
            await recorder.record(result)
        }

        await waitUntilPendingScanExists(in: scheduler)

        await scheduler.cancelAll()
        await probe.waitForCancelledCount(1)
        await waitUntilResultIsRecorded(in: recorder)

        let result = await recorder.result
        #expect(result == .coalesced(coalescedTriggerCount: 1))

        waitTask.cancel()
    }

    private func waitUntilPendingScanExists(in scheduler: SurfaceScanScheduler) async {
        for _ in 0 ..< SurfaceScanSchedulerCancellationTestConstants.waitYieldCount {
            let states = await scheduler.queueStates()
            if states.contains(where: \.hasPendingScan) {
                return
            }
            await Task.yield()
        }
    }

    private func waitUntilResultIsRecorded(in recorder: ScheduleResultRecorder) async {
        for _ in 0 ..< SurfaceScanSchedulerCancellationTestConstants.waitYieldCount {
            let result = await recorder.result
            if result != nil {
                return
            }
            await Task.yield()
        }
    }
}

// MARK: - SurfaceScanSchedulerCancellationTestConstants

private enum SurfaceScanSchedulerCancellationTestConstants {
    static let waitYieldCount = 20
}

// MARK: - ScheduleResultRecorder

private actor ScheduleResultRecorder {
    private(set) var result: SurfaceScanScheduleResult?

    func record(_ result: SurfaceScanScheduleResult) {
        self.result = result
    }
}

// MARK: - CancellableScanProbe

private actor CancellableScanProbe {
    private(set) var startedCount = 0
    private(set) var cancelledCount = 0
    private var startWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var cancelWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

    func runUntilCancelled() async {
        startedCount += 1
        resumeSatisfiedStartWaiters()
        while Task.isCancelled == false {
            await Task.yield()
        }
        cancelledCount += 1
        resumeSatisfiedCancelWaiters()
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
