import SwiftUI

/// One row summarising a surface: icon, name, item count, and when it last changed. When the surface
/// has an open finding the caller passes its severity, drawn as a small glyph on the item-count line.
/// Attention states share the brand's amber; active work uses the violet accent; degradation uses
/// crimson.
struct SurfaceSummaryRow: View {
    let surface: MonitoredSurface
    let summary: SurfaceSummary?
    var findingSeverity: Severity?

    var body: some View {
        HStack(spacing: Metrics.spacingSmall) {
            MonogramChip(surface: surface, isHighlighted: summary?.isScanRunning == true)
            Text(surface.displayName)
                .foregroundStyle(Palette.ink)
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: Metrics.spacingTight) {
                    if let findingSeverity {
                        Image(systemName: findingSeverity.systemImageName)
                            .font(.caption)
                            .foregroundStyle(findingSeverity.tint)
                    }
                    Text(surface.itemCountText(summary?.itemCount ?? 0))
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(Palette.inkMuted)
                }
                SurfaceStatusLine(summary: summary)
                    .font(.caption2)
            }
        }
    }
}
