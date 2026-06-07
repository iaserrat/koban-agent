import SwiftUI

/// The dashboard's verdict: one line answering "is anything wrong right now?", carried by a small
/// status glyph and a strong headline, with every supporting number folded into a single muted line
/// beneath it. The glyph breathes while the agent is live and holds still when something needs
/// attention, so motion conveys state rather than decorating (the brand's motion rule).
struct HomeVerdictHeader: View {
    let status: SystemStatus
    let findingCount: Int
    let totalItemCount: Int
    let monitoredSurfaceCount: Int

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var breathing = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingTight) {
            HStack(spacing: Metrics.spacingSmall) {
                signal
                Text(headline)
                    .font(.title)
                    .fontWeight(.semibold)
                    .tracking(Metrics.headingTracking)
                    .foregroundStyle(Palette.ink)
            }
            Text(subline)
                .font(.callout)
                .foregroundStyle(Palette.inkMuted)
        }
        .onAppear { breathing = true }
    }

    private var signal: some View {
        Image(systemName: status.systemImageName)
            .font(.system(size: Metrics.verdictSignalSize, weight: .medium))
            .foregroundStyle(status.tint)
            .opacity(dimmed ? Metrics.verdictSignalDimOpacity : 1)
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

    private var subline: String {
        switch status {
        case .allClear: inventorySummary
        case .starting: "Indexing your Mac for the first time"
        case .degraded: "A monitored surface stopped reporting"
        case .dataUnavailable: "Showing the last known view while reads recover"
        case let .findings(severity): "Worst severity \(severity.label) · \(inventorySummary)"
        }
    }

    /// The one number not shown anywhere else on the page: the total tracked across every surface,
    /// with its surface count for context. The list below names the surfaces; this only sums them.
    private var inventorySummary: String {
        let items = "\(totalItemCount.formatted()) \(totalItemCount == 1 ? "item" : "items")"
        let surfaces = "\(monitoredSurfaceCount) \(monitoredSurfaceCount == 1 ? "surface" : "surfaces")"
        return "\(items) across \(surfaces)"
    }
}
