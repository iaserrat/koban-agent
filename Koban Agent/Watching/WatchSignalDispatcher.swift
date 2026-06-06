import Foundation

/// `@unchecked Sendable` is justified: every mutable property (`pending`, `activeDrainID`,
/// `drainTask`) is read and written only while holding `lock`, so concurrent `enqueue`/`cancel`
/// calls from the FSEvents callback thread and the engine are fully serialised.
final class WatchSignalDispatcher: @unchecked Sendable {
    private let onSignal: @Sendable (WatchSignal) async -> Void
    private let lock = NSLock()
    private let makeID: @Sendable () -> UUID

    private var pending: WatchSignal?
    private var activeDrainID: UUID?
    private var drainTask: Task<Void, Never>?

    init(
        makeID: @escaping @Sendable () -> UUID = UUID.init,
        onSignal: @escaping @Sendable (WatchSignal) async -> Void
    ) {
        self.makeID = makeID
        self.onSignal = onSignal
    }

    func enqueue(_ signal: WatchSignal) {
        lock.lock()
        pending = pending?.merged(with: signal) ?? signal
        guard drainTask == nil else {
            lock.unlock()
            return
        }
        let drainID = makeID()
        activeDrainID = drainID
        let task = Task { [weak self] in
            guard let self else { return }
            await drain(drainID: drainID)
        }
        drainTask = task
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        pending = nil
        activeDrainID = nil
        let task = drainTask
        drainTask = nil
        lock.unlock()
        task?.cancel()
    }

    private func drain(drainID: UUID) async {
        while Task.isCancelled == false {
            guard let signal = nextSignal(drainID: drainID) else { return }
            await onSignal(signal)
        }
        finishDrain(drainID: drainID)
    }

    private func nextSignal(drainID: UUID) -> WatchSignal? {
        lock.lock()
        defer { lock.unlock() }
        guard activeDrainID == drainID else { return nil }
        guard let signal = pending else {
            activeDrainID = nil
            drainTask = nil
            return nil
        }
        pending = nil
        return signal
    }

    private func finishDrain(drainID: UUID) {
        lock.lock()
        if activeDrainID == drainID {
            activeDrainID = nil
            drainTask = nil
        }
        lock.unlock()
    }
}
