import Foundation
import Testing
@testable import Koban_Agent

// MARK: - PublishSchedulerTests

struct PublishSchedulerTests {
    @Test
    func coalescesRepeatedPublishRequestsWhilePublishIsRunning() async {
        let scheduler = PublishScheduler()
        let probe = PublishProbe()

        await scheduler.schedule {
            await probe.run()
        }
        await probe.waitForStartedCount(1)

        await scheduler.schedule {
            await probe.run()
        }
        await scheduler.schedule {
            await probe.run()
        }

        await probe.finishNext()
        await probe.waitForStartedCount(2)
        await probe.finishNext()

        let count = await probe.startedCount
        #expect(count == 2)
    }

    @Test
    func cancelStopsRunningPublishAndDropsPendingPublish() async {
        let scheduler = PublishScheduler()
        let probe = PublishProbe()

        await scheduler.schedule {
            await probe.runUntilCancelled()
        }
        await probe.waitForStartedCount(1)

        await scheduler.schedule {
            await probe.run()
        }

        await scheduler.cancel()
        await probe.waitForCancelledCount(1)

        let count = await probe.startedCount
        #expect(count == 1)
    }

    @Test
    func cancelledPublishCannotClearNewerRunningPublish() async {
        let scheduler = PublishScheduler()
        let probe = PublishProbe()

        await scheduler.schedule {
            await probe.runUntilCancelledThenWait()
        }
        await probe.waitForStartedCount(1)
        await scheduler.cancel()
        await probe.waitForCancelledCount(1)
        await probe.waitForFinishWaiterCount(1)

        await scheduler.schedule {
            await probe.run()
        }
        await probe.waitForStartedCount(2)
        await probe.waitForFinishWaiterCount(2)
        await probe.finishNext()

        await scheduler.schedule {
            await probe.run()
        }
        await Task.yield()

        let countBeforeCurrentPublishFinishes = await probe.startedCount
        #expect(countBeforeCurrentPublishFinishes == 2)

        await probe.finishNext()
        await probe.waitForStartedCount(3)
        await probe.finishNext()
    }
}

// MARK: - PublishProbe

private actor PublishProbe {
    private(set) var startedCount = 0
    private(set) var cancelledCount = 0
    private(set) var finishWaiterCount = 0
    private var finishContinuations: [CheckedContinuation<Void, Never>] = []
    private var startWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var cancelWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var finishWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

    func run() async {
        startedCount += 1
        resumeSatisfiedStartWaiters()
        await withCheckedContinuation { continuation in
            finishWaiterCount += 1
            finishContinuations.append(continuation)
            resumeSatisfiedFinishWaiters()
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
            finishWaiterCount += 1
            finishContinuations.append(continuation)
            resumeSatisfiedFinishWaiters()
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

    func waitForFinishWaiterCount(_ count: Int) async {
        guard finishWaiterCount < count else { return }
        await withCheckedContinuation { continuation in
            finishWaiters.append((count, continuation))
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

    private func resumeSatisfiedFinishWaiters() {
        let ready = finishWaiters.filter { finishWaiterCount >= $0.0 }
        finishWaiters.removeAll { finishWaiterCount >= $0.0 }
        for waiter in ready {
            waiter.1.resume()
        }
    }
}
