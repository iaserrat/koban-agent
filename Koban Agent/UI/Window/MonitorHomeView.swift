import SwiftUI

/// The window's default scope: a birds-eye dashboard. A single colour-coded verdict hero, a row of
/// KPI tiles, and the surface grid sit in a centred column over the system strip. The verdict fuses
/// monitoring health with the worst open finding (`SystemStatus`), so the page answers "is anything
/// wrong?" before the eye moves anywhere else.
struct MonitorHomeView: View {
    let state: AppState
    let data: WindowDataModel
    let updater: UpdaterModel?

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ScrollView {
                    content(columnCount: surfaceColumnCount(for: contentWidth(in: proxy.size.width)))
                        .frame(maxWidth: Metrics.homeContentMaxWidth)
                        .padding(Metrics.homeContentPadding)
                        // Fill the width up to the cap, and centre vertically: with the content
                        // shorter than the window it sits in the optical middle; otherwise it scrolls.
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
            }
            HomeSystemStrip(syncStatus: state.syncStatus, updater: updater)
        }
        .background(Palette.bg)
    }

    private func content(columnCount: Int) -> some View {
        VStack(spacing: Metrics.homeSectionSpacing) {
            HomeStatusHero(
                status: status,
                findingCount: data.findingGroups.count,
                monitoredSurfaceCount: MonitoredSurface.allCases.count
            )
            HomeStatsRow(
                itemCount: totalItemCount,
                findingCount: data.findingGroups.count,
                worstSeverity: worstSeverity,
                monitoredSurfaceCount: MonitoredSurface.allCases.count
            )
            surfacesSection(columnCount: columnCount)
        }
    }

    private func surfacesSection(columnCount: Int) -> some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            SectionLabel(title: "Surfaces")
            HomeSurfaceGrid(
                columnCount: columnCount,
                summaries: state.summaries,
                severityBySurface: severityBySurface
            )
        }
    }

    /// The content's laid-out width: the viewport minus gutters, capped at the max so the grid's
    /// breakpoints are measured against the width the cards actually get.
    private func contentWidth(in viewportWidth: CGFloat) -> CGFloat {
        let capped = min(viewportWidth, Metrics.homeContentMaxWidth)
        return capped - Metrics.homeContentPadding - Metrics.homeContentPadding
    }

    private func surfaceColumnCount(for width: CGFloat) -> Int {
        if width >= Metrics.homeWideBreakpoint {
            Metrics.homeSurfaceColumns
        } else if width >= Metrics.homeMediumBreakpoint {
            Metrics.homeSurfaceColumnsMedium
        } else {
            1
        }
    }

    private var status: SystemStatus {
        SystemStatus.evaluate(
            readModelFailed: state.readModelError != nil,
            isMonitoring: state.isMonitoring,
            hasCompletedInitialScan: hasCompletedInitialScan,
            overallHealth: overallHealth,
            worstFindingSeverity: worstSeverity
        )
    }

    private var overallHealth: SurfaceHealthState {
        state.summaries.values.map(\.healthState).max() ?? .idle
    }

    private var hasCompletedInitialScan: Bool {
        state.summaries.values.contains { $0.lastScanCompletedAt != nil }
    }

    private var worstSeverity: Severity? {
        data.findingGroups.map(\.representative.severity).max()
    }

    private var totalItemCount: Int {
        data.inventoryCountsBySurface.values.reduce(0, +)
    }

    /// The worst open severity per surface, used to badge the surface cards.
    private var severityBySurface: [MonitoredSurface: Severity] {
        data.findingGroups.reduce(into: [:]) { result, group in
            let severity = group.representative.severity
            let surface = group.representative.surface
            result[surface] = Swift.max(result[surface] ?? severity, severity)
        }
    }
}
