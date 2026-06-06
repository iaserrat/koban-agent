import SwiftUI

/// A crisp, steady status dot: a single filled circle in a colour the caller has already resolved
/// from health. It carries a steady state (monitoring, idle, degraded) where the signal is the
/// colour, not motion, so it stays calm and legible. For transient, in-progress work that should
/// read as "happening right now", use the breathing `LiveIndicator` instead.
struct StatusDot: View {
    /// The dot's colour, already resolved from health by the caller.
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: Metrics.statusDotSize, height: Metrics.statusDotSize)
    }
}
