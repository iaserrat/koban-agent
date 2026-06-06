import Foundation

// MARK: - ScanRuntime

struct ScanRuntime {
    let now: @Sendable () -> Date
    let makeID: @Sendable () -> UUID

    static let live = Self(
        now: { Date() },
        makeID: { UUID() }
    )
}
