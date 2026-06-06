import Foundation

/// A held, instrumented publish operation for `PublishScheduler` contention gates.
///
/// It records how many publishes started, how many were cancelled, and the peak number
/// running at once, and lets a test hold a publish in flight (`run`) or cancel it
/// (`runUntilCancelled`) so coalescing and stale-completion guards can be observed
/// deterministically.
actor PublishStressProbe {
    private(set) var startedCount = 0
    private(set) var cancelledCount = 0
    private(set) var maxConcurrent = 0

    private var concurrent = 0
    private var finishContinuations: [CheckedContinuation<Void, Never>] = []
    private var startWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var cancelWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var idleWaiters: [CheckedContinuation<Void, Never>] = []

    func run() async {
        enter()
        await withCheckedContinuation { continuation in
            finishContinuations.append(continuation)
        }
        leave()
    }

    func runUntilCancelled() async {
        enter()
        while Task.isCancelled == false {
            await Task.yield()
        }
        cancelledCount += 1
        resumeCancelWaiters()
        leave()
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

    func finishNext() {
        guard finishContinuations.isEmpty == false else { return }
        finishContinuations.removeFirst().resume()
    }

    private func enter() {
        startedCount += 1
        concurrent += 1
        maxConcurrent = max(maxConcurrent, concurrent)
        resumeStartWaiters()
    }

    private func leave() {
        concurrent -= 1
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
