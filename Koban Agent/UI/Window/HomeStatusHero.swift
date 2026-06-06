import SwiftUI

/// The dashboard's centrepiece: one large, colour-coded emblem answering "is anything wrong right
/// now?", with a headline verdict and a one-line supporting fact. The emblem breathes while the
/// agent is live, and holds still when something needs attention, so motion conveys state rather
/// than decorating (the brand's motion rule).
struct HomeStatusHero: View {
    let status: SystemStatus
    let findingCount: Int
    let monitoredSurfaceCount: Int

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var breathing = false

    var body: some View {
        VStack(spacing: Metrics.homeHeroSpacing) {
            emblem
            VStack(spacing: Metrics.spacingTight) {
                Text(headline)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.ink)
                Text(subhead)
                    .font(.callout)
                    .foregroundStyle(Palette.inkMuted)
            }
            .multilineTextAlignment(.center)
        }
        .onAppear { breathing = true }
    }

    private var emblem: some View {
        Image(systemName: status.systemImageName)
            .font(.system(size: Metrics.heroGlyphSize, weight: .medium))
            .foregroundStyle(status.tint)
            .frame(width: Metrics.heroEmblemSize, height: Metrics.heroEmblemSize)
            .background(Circle().fill(status.tint.opacity(Metrics.heroFillOpacity)))
            .overlay(
                Circle().strokeBorder(
                    status.tint.opacity(Metrics.heroStrokeOpacity),
                    lineWidth: Metrics.hairline
                )
            )
            .background(glow)
    }

    /// A soft blurred disc of the verdict's colour. On the live states a single state change on
    /// `breathing` kicks off a perpetual, autoreversing fade, so the halo breathes; problem states
    /// leave it lit and steady.
    private var glow: some View {
        Circle()
            .fill(status.tint)
            .frame(width: Metrics.heroGlowSize, height: Metrics.heroGlowSize)
            .blur(radius: Metrics.heroGlowBlur)
            .opacity(dimmed ? Metrics.heroGlowDimOpacity : Metrics.heroGlowLitOpacity)
            .animation(breathingAnimation, value: breathing)
    }

    private var dimmed: Bool {
        status.isLive && reduceMotion == false && breathing
    }

    private var breathingAnimation: Animation? {
        guard status.isLive, reduceMotion == false else { return nil }
        return .easeInOut(duration: Metrics.livePulseSeconds).repeatForever(autoreverses: true)
    }

    private var headline: String {
        switch status {
        case .allClear: "All clear"
        case .starting: "Getting set up"
        case .degraded: "Monitoring degraded"
        case .dataUnavailable: "Data unavailable"
        case .findings: findingCount == 1 ? "1 finding to review" : "\(findingCount) findings to review"
        }
    }

    private var subhead: String {
        switch status {
        case .allClear:
            "Watching \(monitoredSurfaceCount) \(monitoredSurfaceCount == 1 ? "surface" : "surfaces")"
        case .starting:
            "Indexing your Mac for the first time"
        case .degraded:
            "A monitored surface stopped reporting"
        case .dataUnavailable:
            "Showing the last known view while reads recover"
        case let .findings(severity):
            "Worst severity: \(severity.label)"
        }
    }
}
