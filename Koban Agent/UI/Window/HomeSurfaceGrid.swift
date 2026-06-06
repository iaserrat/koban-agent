import SwiftUI

/// The responsive grid of surface cards: every monitored surface at a glance, in
/// `MonitoredSurface`'s declared order so the layout is stable across refreshes. The column count is
/// chosen by the parent from the available width, so the cards stretch to fill the window and reflow
/// as it narrows.
struct HomeSurfaceGrid: View {
    let columnCount: Int
    let summaries: [MonitoredSurface: SurfaceSummary]
    let severityBySurface: [MonitoredSurface: Severity]

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: Metrics.homeCardSpacing),
            count: columnCount
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Metrics.homeCardSpacing) {
            ForEach(MonitoredSurface.allCases) { surface in
                SurfaceSummaryCard(
                    surface: surface,
                    summary: summaries[surface],
                    findingSeverity: severityBySurface[surface]
                )
            }
        }
    }
}
