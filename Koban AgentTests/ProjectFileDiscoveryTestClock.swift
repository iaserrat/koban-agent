import Foundation

final class ProjectFileDiscoveryTestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var ticks = 0

    func now() -> Date {
        lock.lock()
        defer {
            ticks += 1
            lock.unlock()
        }
        return Date(timeIntervalSinceReferenceDate: TimeInterval(ticks))
    }
}
