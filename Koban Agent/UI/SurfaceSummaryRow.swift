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
                Text(surface.itemCountText(summary?.itemCount ?? 0))
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(Palette.inkMuted)
                SurfaceStatusLine(summary: summary)
                    .font(.caption2)
            }
        }
    }
}
