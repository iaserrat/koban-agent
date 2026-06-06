import SwiftUI

/// A breathing dot for transient, in-progress work (e.g. a surface being indexed): a status dot
/// wrapped in a soft glow of its own colour, slowly breathing so the row reads as actively
/// happening rather than merely on. The breathing is suppressed under Reduce Motion, leaving a
/// calm, legible dot (the brand keeps motion to conveyed state, never decoration). For a steady
/// status that should hold still, use `StatusDot`.
struct LiveIndicator: View {
    /// The dot's colour, already resolved by the caller.
    let color: Color

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var breathing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: Metrics.statusDotSize, height: Metrics.statusDotSize)
            .background(glow)
            .opacity(dimmed ? Metrics.liveGlowDimOpacity : 1)
            .animation(breathingAnimation, value: breathing)
            .onAppear { breathing = true }
    }

    private var glow: some View {
        Circle()
            .fill(color)
            .frame(width: Metrics.liveGlowSize, height: Metrics.liveGlowSize)
            .blur(radius: Metrics.liveGlowBlur)
            .opacity(dimmed ? Metrics.liveGlowDimOpacity : 1)
    }

    /// True only on the dim half of a breath, and only while motion is allowed.
    private var dimmed: Bool {
        reduceMotion == false && breathing
    }

    private var breathingAnimation: Animation? {
        guard reduceMotion == false else { return nil }
        return .easeInOut(duration: Metrics.livePulseSeconds).repeatForever(autoreverses: true)
    }
}
