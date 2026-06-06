import Foundation
import Testing
@testable import Koban_Agent

// MARK: - WatchSignalDispatcherTests

struct WatchSignalDispatcherTests {
    @Test
    func coalescesSignalsWhileDispatchIsRunning() async {
        let probe = WatchSignalDispatchProbe()
        let dispatcher = WatchSignalDispatcher { signal in
            await probe.handle(signal)
        }

        dispatcher.enqueue(WatchSignal(surfaces: [.homebrew], degradationReason: nil))
        await probe.waitForHandledCount(1)

        dispatcher.enqueue(WatchSignal(surfaces: [.codexConfig], degradationReason: nil))
        dispatcher.enqueue(
            WatchSignal(surfaces: [.claudeConfig], degradationReason: HealthMessages.watchEventsDropped)
        )

        await Task.yield()
        #expect(await probe.handledCount == 1)

        await probe.releaseNext()
        await probe.waitForHandledCount(2)
        let signals = await probe.signals

        #expect(signals[1].surfaces == [.codexConfig, .claudeConfig])
        #expect(signals[1].degradationReason == HealthMessages.watchEventsDropped)

        await probe.releaseNext()
    }
}

// MARK: - WatchSignalDispatchProbe

private actor WatchSignalDispatchProbe {
    private(set) var signals: [WatchSignal] = []
    private var releaseContinuations: [CheckedContinuation<Void, Never>] = []
    private var waiters: [(Int, CheckedContinuation<Void, Never>)] = []

    var handledCount: Int {
        signals.count
    }

    func handle(_ signal: WatchSignal) async {
        signals.append(signal)
        resumeSatisfiedWaiters()
        await withCheckedContinuation { continuation in
            releaseContinuations.append(continuation)
        }
    }

    func waitForHandledCount(_ count: Int) async {
        guard signals.count < count else { return }
        await withCheckedContinuation { continuation in
            waiters.append((count, continuation))
        }
    }

    func releaseNext() {
        guard releaseContinuations.isEmpty == false else { return }
        releaseContinuations.removeFirst().resume()
    }

    private func resumeSatisfiedWaiters() {
        let ready = waiters.filter { signals.count >= $0.0 }
        waiters.removeAll { signals.count >= $0.0 }
        for waiter in ready {
            waiter.1.resume()
        }
    }
}
