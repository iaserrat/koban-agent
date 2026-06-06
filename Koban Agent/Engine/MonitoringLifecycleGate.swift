import Foundation

actor MonitoringLifecycleGate {
    private let makeID: @Sendable () -> UUID

    private var activeGeneration: UUID?

    init(makeID: @escaping @Sendable () -> UUID = UUID.init) {
        self.makeID = makeID
    }

    func start() -> UUID {
        let generation = makeID()
        activeGeneration = generation
        return generation
    }

    func stop() {
        activeGeneration = nil
    }

    func current() -> UUID? {
        activeGeneration
    }

    func isActive(_ generation: UUID) -> Bool {
        activeGeneration == generation
    }
}
