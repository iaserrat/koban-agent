import Foundation

/// Collapses a burst of change notifications into a single delayed action. FSEvents fires
/// many times during one `brew install`; we want exactly one rescan once the dust settles.
/// Each `signal()` restarts the timer, so the action runs `delay` after the *last* signal.
actor WatchDebouncer {
    private let delay: Duration
    private let action: @Sendable () async -> Void
    private var pending: Task<Void, Never>?

    init(delay: Duration, action: @escaping @Sendable () async -> Void) {
        self.delay = delay
        self.action = action
    }

    func signal() {
        pending?.cancel()
        pending = Task { [delay, action] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            guard Task.isCancelled == false else { return }
            await action()
        }
    }

    func cancel() {
        pending?.cancel()
        pending = nil
    }
}
