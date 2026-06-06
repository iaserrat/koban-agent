import SwiftUI

/// One row summarising a surface: icon, name, item count, and when it last changed. Attention
/// states share the brand's amber; active work uses the violet accent; degradation uses crimson.
struct SurfaceSummaryRow: View {
    let surface: MonitoredSurface
    let summary: SurfaceSummary?

    var body: some View {
        HStack(spacing: Metrics.spacingSmall) {
            MonogramChip(surface: surface, isHighlighted: summary?.isScanRunning == true)
            Text(surface.displayName)
                .foregroundStyle(Palette.ink)
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(countText)
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(Palette.inkMuted)
                secondaryLine
                    .font(.caption2)
            }
        }
    }

    /// The single line under the count: the most urgent active state, or the last change time
    /// when nothing needs attention.
    @ViewBuilder private var secondaryLine: some View {
        if summary?.healthState == .degraded {
            Text(SurfaceHealthLabels.degraded).foregroundStyle(Palette.critical)
        } else if summary?.healthState == .stale {
            Text(SurfaceHealthLabels.stale).foregroundStyle(Palette.alertInk)
        } else if summary?.hasPendingScan == true {
            Text(SurfaceHealthLabels.queued).foregroundStyle(Palette.alertInk)
        } else if summary?.isScanRunning == true {
            Text(SurfaceHealthLabels.scanning).foregroundStyle(Palette.accent)
        } else if let lastChange = summary?.lastChange {
            Text(lastChange, format: .relative(presentation: .named)).foregroundStyle(Palette.inkSubtle)
        }
    }

    private var countText: String {
        let count = summary?.itemCount ?? 0
        let noun = count == 1 ? surface.itemNoun : surface.itemNoun + "s"
        return "\(count) \(noun)"
    }
}
