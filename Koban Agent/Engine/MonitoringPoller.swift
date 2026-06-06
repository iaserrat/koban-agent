import Foundation

actor MonitoringPoller {
    private let interval: Duration
    private let surfaces: [MonitoredSurface]

    private var task: Task<Void, Never>?

    init(interval: Duration, surfaces: [MonitoredSurface]) {
        self.interval = interval
        self.surfaces = surfaces
    }

    func start(action: @escaping @Sendable (MonitoredSurface) async -> Void) {
        task?.cancel()
        task = Task { [interval, surfaces] in
            while Task.isCancelled == false {
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }
                guard Task.isCancelled == false else { return }
                for surface in surfaces {
                    await action(surface)
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
