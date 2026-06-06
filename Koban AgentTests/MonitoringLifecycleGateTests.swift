import Foundation
import Testing
@testable import Koban_Agent

// MARK: - MonitoringLifecycleGateTests

struct MonitoringLifecycleGateTests {
    @Test
    func stopInvalidatesCallbacksFromEarlierGeneration() async throws {
        let firstID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000201"))
        let secondID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000202"))
        let ids = LifecycleIDSequence([firstID, secondID])
        let gate = MonitoringLifecycleGate(makeID: { ids.next() })

        let firstGeneration = await gate.start()
        await gate.stop()
        let secondGeneration = await gate.start()

        #expect(firstGeneration == firstID)
        #expect(secondGeneration == secondID)
        #expect(await gate.isActive(firstGeneration) == false)
        #expect(await gate.isActive(secondGeneration))
        #expect(await gate.current() == secondGeneration)
    }
}

// MARK: - LifecycleIDSequence

private final class LifecycleIDSequence: @unchecked Sendable {
    private let lock = NSLock()
    private var ids: [UUID]

    init(_ ids: [UUID]) {
        self.ids = ids
    }

    func next() -> UUID {
        lock.lock()
        defer { lock.unlock() }
        return ids.removeFirst()
    }
}
