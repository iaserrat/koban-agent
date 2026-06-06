import Foundation

actor SyncPoller {
    private let interval: Duration

    private var task: Task<Void, Never>?

    init(interval: Duration) {
        self.interval = interval
    }

    func start(action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task { [interval] in
            while Task.isCancelled == false {
                await action()
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
