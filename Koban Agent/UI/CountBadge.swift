import SwiftUI

/// A small "xN" badge shown when a row stands for several collapsed occurrences. The count is
/// itself a signal: a condition that recurred many times deserves attention. Renders nothing
/// for a single occurrence, so callers can drop it in unconditionally.
struct CountBadge: View {
    let count: Int

    var body: some View {
        if count > 1 {
            Text("\(count)x")
                .font(.caption2)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Palette.inkMuted)
                .padding(.horizontal, Metrics.badgePaddingH)
                .padding(.vertical, Metrics.badgePaddingV)
                .background(Capsule().fill(Palette.surfaceRaised))
        }
    }
}
