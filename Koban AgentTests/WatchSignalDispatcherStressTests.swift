import Foundation
import Testing
@testable import Koban_Agent

// MARK: - WatchSignalDispatcherStressTests

/// Stress/load gate for `WatchSignalDispatcher` under high-volume watcher bursts.
///
/// The gate is deterministic on purpose: it never sleeps or reads the wall clock. The
/// recorded budgets are logical counts (handled dispatches, peak concurrent handlers,
/// peak coalesced surfaces) rather than timings, which is what the charter's
/// "no wall-clock dependence" rule requires while still proving the work stays bounded.
struct WatchSignalDispatcherStressTests {
    private static let burstSize = 5000

    @Test
    func highVolumeBurstCoalescesIntoBoundedWork() async {
        let probe = BurstProbe()
        let dispatcher = WatchSignalDispatcher { signal in
            await probe.handle(signal)
        }

        // First signal occupies the single drain task and blocks inside the handler.
        dispatcher.enqueue(WatchSignal(surfaces: [.homebrew], degradationReason: nil))
        await probe.waitForHandledCount(1)

        // While the handler is held, slam the dispatcher with a high-volume burst that
        // covers every surface and every degradation reason.
        for index in 0 ..< Self.burstSize {
            dispatcher.enqueue(burstSignal(index: index))
        }

        // No additional handler may start while the first one is still held: the drain
        // task count stays bounded at one regardless of burst size.
        for _ in 0 ..< 16 {
            await Task.yield()
        }
        #expect(await probe.handledCount == 1)

        // Releasing the first handler drains the entire coalesced burst as one signal.
        await probe.releaseNext()
        await probe.waitForHandledCount(2)
        await probe.releaseNext()
        await probe.waitForDrainIdle()

        let signals = await probe.signals
        #expect(signals.count == 2)

        // Coalescing preserves every affected surface across the whole burst.
        #expect(signals[1].surfaces == Set(MonitoredSurface.allCases))

        // The strongest degradation reason survives coalescing (dropped beats wrapped
        // beats root-changed).
        #expect(signals[1].degradationReason == HealthMessages.watchEventsDropped)

        // Recorded budgets: bounded handler concurrency and bounded dispatch count.
        #expect(await probe.maxConcurrent == 1)
        #expect(await probe.handledCount == 2)
    }

    @Test
    func freeRunningBurstNeverDropsASurface() async {
        let probe = BurstProbe(holdHandlers: false)
        let dispatcher = WatchSignalDispatcher { signal in
            await probe.handle(signal)
        }

        for index in 0 ..< Self.burstSize {
            dispatcher.enqueue(WatchSignal(surfaces: [surface(index: index)], degradationReason: nil))
        }

        // Wait until the union of every handled signal covers all surfaces, then confirm
        // the drain returns to idle with no leaked task.
        await probe.waitForUnion(Set(MonitoredSurface.allCases))
        await probe.waitForDrainIdle()

        #expect(await probe.union == Set(MonitoredSurface.allCases))
        #expect(await probe.maxConcurrent == 1)
        // Coalescing must have collapsed the burst well below one dispatch per enqueue.
        #expect(await probe.handledCount <= Self.burstSize)
    }

    @Test
    func eachDegradationReasonSurvivesCoalescing() async {
        await expectCoalescedReason(
            [HealthMessages.watchRootChanged, HealthMessages.watchEventIDsWrapped],
            isStrongest: HealthMessages.watchEventIDsWrapped
        )
        await expectCoalescedReason(
            [HealthMessages.watchEventIDsWrapped, HealthMessages.watchEventsDropped],
            isStrongest: HealthMessages.watchEventsDropped
        )
        await expectCoalescedReason(
            [HealthMessages.watchRootChanged, nil],
            isStrongest: HealthMessages.watchRootChanged
        )
    }

    private func expectCoalescedReason(_ reasons: [String?], isStrongest expected: String?) async {
        let probe = BurstProbe()
        let dispatcher = WatchSignalDispatcher { signal in
            await probe.handle(signal)
        }

        dispatcher.enqueue(WatchSignal(surfaces: [.homebrew], degradationReason: nil))
        await probe.waitForHandledCount(1)

        for reason in reasons {
            dispatcher.enqueue(WatchSignal(surfaces: [.homebrew], degradationReason: reason))
        }

        await probe.releaseNext()
        await probe.waitForHandledCount(2)
        await probe.releaseNext()
        await probe.waitForDrainIdle()

        let signals = await probe.signals
        #expect(signals[1].degradationReason == expected)
    }

    private func burstSignal(index: Int) -> WatchSignal {
        let reasons: [String?] = [
            nil,
            HealthMessages.watchRootChanged,
            HealthMessages.watchEventIDsWrapped,
            HealthMessages.watchEventsDropped
        ]

        return WatchSignal(
            surfaces: [surface(index: index)],
            degradationReason: reasons[index % reasons.count]
        )
    }

    private func surface(index: Int) -> MonitoredSurface {
        let all = MonitoredSurface.allCases
        return all[index % all.count]
    }
}

// MARK: - BurstProbe

private actor BurstProbe {
    private(set) var signals: [WatchSignal] = []
    private(set) var maxConcurrent = 0
    private(set) var union: Set<MonitoredSurface> = []

    private let holdHandlers: Bool
    private var concurrent = 0
    private var releaseContinuations: [CheckedContinuation<Void, Never>] = []
    private var countWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var unionWaiters: [(Set<MonitoredSurface>, CheckedContinuation<Void, Never>)] = []
    private var idleWaiters: [CheckedContinuation<Void, Never>] = []

    init(holdHandlers: Bool = true) {
        self.holdHandlers = holdHandlers
    }

    var handledCount: Int {
        signals.count
    }

    func handle(_ signal: WatchSignal) async {
        concurrent += 1
        maxConcurrent = max(maxConcurrent, concurrent)
        signals.append(signal)
        union.formUnion(signal.surfaces)
        resumeSatisfiedCountWaiters()
        resumeSatisfiedUnionWaiters()
        if holdHandlers {
            await withCheckedContinuation { continuation in
                releaseContinuations.append(continuation)
            }
        } else {
            await Task.yield()
        }
        concurrent -= 1
        resumeIdleWaitersIfQuiescent()
    }

    func waitForHandledCount(_ count: Int) async {
        guard signals.count < count else { return }
        await withCheckedContinuation { continuation in
            countWaiters.append((count, continuation))
        }
    }

    func waitForUnion(_ surfaces: Set<MonitoredSurface>) async {
        guard surfaces.isSubset(of: union) == false else { return }
        await withCheckedContinuation { continuation in
            unionWaiters.append((surfaces, continuation))
        }
    }

    /// Resolves once no handler is executing and nothing is held, which means the drain
    /// task has finished and no task leaked.
    func waitForDrainIdle() async {
        guard concurrent > 0 || releaseContinuations.isEmpty == false else { return }
        await withCheckedContinuation { continuation in
            idleWaiters.append(continuation)
        }
    }

    func releaseNext() {
        guard releaseContinuations.isEmpty == false else { return }
        releaseContinuations.removeFirst().resume()
    }

    private func resumeSatisfiedCountWaiters() {
        let ready = countWaiters.filter { signals.count >= $0.0 }
        countWaiters.removeAll { signals.count >= $0.0 }
        for waiter in ready {
            waiter.1.resume()
        }
    }

    private func resumeSatisfiedUnionWaiters() {
        let ready = unionWaiters.filter { $0.0.isSubset(of: union) }
        unionWaiters.removeAll { $0.0.isSubset(of: union) }
        for waiter in ready {
            waiter.1.resume()
        }
    }

    private func resumeIdleWaitersIfQuiescent() {
        guard concurrent == 0, releaseContinuations.isEmpty else { return }
        let ready = idleWaiters
        idleWaiters.removeAll()
        for waiter in ready {
            waiter.resume()
        }
    }
}
