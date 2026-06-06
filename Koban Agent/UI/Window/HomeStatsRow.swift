import SwiftUI

/// The row of KPI tiles under the hero: what is tracked, what is flagged, and how many surfaces are
/// watched. Three equal-width tiles, so the row stays balanced at any window size.
struct HomeStatsRow: View {
    let itemCount: Int
    let findingCount: Int
    let worstSeverity: Severity?
    let monitoredSurfaceCount: Int

    var body: some View {
        HStack(spacing: Metrics.homeCardSpacing) {
            HomeStatTile(label: "Tracked", value: itemCount.formatted(), caption: "items")
            HomeStatTile(
                label: "Findings",
                value: findingCount.formatted(),
                caption: worstSeverity?.label ?? "none open",
                valueTint: worstSeverity?.tint ?? Palette.ink
            )
            HomeStatTile(label: "Surfaces", value: monitoredSurfaceCount.formatted(), caption: "watched")
        }
    }
}
