import SwiftUI

/// The single line of secondary status for a surface: the most urgent active state, or the last
/// change time when nothing needs attention. Defined once and rendered in both the menu-bar panel's
/// `SurfaceSummaryRow` and the home dashboard's `SurfaceSummaryCard`, so the two never drift (see
/// CLAUDE.md: one component, many contexts).
struct SurfaceStatusLine: View {
    let summary: SurfaceSummary?

    var body: some View {
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
}
