import SwiftUI

/// One surface as a card in the home dashboard's grid: the ecosystem monogram and name, a health
/// dot, an item count, and the shared status line. A severity glyph appears when the surface has an
/// open finding. The same surface summary the panel renders as a row (`SurfaceSummaryRow`), laid out
/// for the grid instead of a list (CLAUDE.md: one component, many contexts).
struct SurfaceSummaryCard: View {
    let surface: MonitoredSurface
    let summary: SurfaceSummary?
    let findingSeverity: Severity?

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingTight) {
            HStack(spacing: Metrics.spacingSmall) {
                MonogramChip(surface: surface, isHighlighted: summary?.isScanRunning == true)
                Text(surface.displayName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: Metrics.spacingTight)
                if let findingSeverity {
                    Image(systemName: findingSeverity.systemImageName)
                        .font(.caption2)
                        .foregroundStyle(findingSeverity.tint)
                }
                StatusDot(color: (summary?.healthState ?? .idle).tint)
            }
            Text(surface.itemCountText(summary?.itemCount ?? 0))
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(Palette.inkMuted)
            Spacer(minLength: 0)
            SurfaceStatusLine(summary: summary)
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: Metrics.homeSurfaceCardHeight, alignment: .topLeading)
        .padding(Metrics.spacingMedium)
        .kobanPanel()
    }
}
