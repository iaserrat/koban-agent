import SwiftUI

/// Every monitored surface as a single hairline-divided list, in `MonitoredSurface`'s declared order
/// so the layout is stable across refreshes. Each entry is the shared `SurfaceSummaryRow` the
/// menu-bar panel renders (CLAUDE.md: one component, many contexts), here grouped in one panel with
/// hairline dividers instead of a grid of cards, so the surfaces read as a calm, scannable index.
struct HomeSurfaceList: View {
    let summaries: [MonitoredSurface: SurfaceSummary]
    let severityBySurface: [MonitoredSurface: Severity]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(MonitoredSurface.allCases.enumerated()), id: \.element) { index, surface in
                if index > 0 {
                    Rectangle()
                        .fill(Palette.border)
                        .frame(height: Metrics.hairline)
                }
                SurfaceSummaryRow(
                    surface: surface,
                    summary: summaries[surface],
                    findingSeverity: severityBySurface[surface]
                )
                .padding(.horizontal, Metrics.spacingLarge)
                .padding(.vertical, Metrics.spacingMedium)
            }
        }
        .kobanPanel()
    }
}
