import Foundation

actor PublishScheduler {
    private let makeID: @Sendable () -> UUID

    private var running: Task<Void, Never>?
    private var runningID: UUID?
    private var pending = false

    init(makeID: @escaping @Sendable () -> UUID = UUID.init) {
        self.makeID = makeID
    }

    func schedule(operation: @escaping @Sendable () async -> Void) {
        if running != nil {
            pending = true
            return
        }

        start(operation: operation)
    }

    func cancel() {
        pending = false
        let task = running
        running = nil
        runningID = nil
        task?.cancel()
    }

    private func start(operation: @escaping @Sendable () async -> Void) {
        let publishID = makeID()
        runningID = publishID
        running = Task {
            await operation()
            finish(publishID: publishID, operation: operation)
        }
    }

    private func finish(publishID: UUID, operation: @escaping @Sendable () async -> Void) {
        guard runningID == publishID else { return }
        if pending {
            pending = false
            start(operation: operation)
        } else {
            running = nil
            runningID = nil
        }
    }
}
