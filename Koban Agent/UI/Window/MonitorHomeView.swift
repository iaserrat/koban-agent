import SwiftUI

/// The window's default scope: a birds-eye dashboard. One colour-coded verdict answering "is
/// anything wrong?" sits over a single list of every watched surface, in a top-anchored, centred
/// column above the system strip. The verdict fuses monitoring health with the worst open finding
/// (`SystemStatus`), so the page answers the question before the eye moves to the list.
struct MonitorHomeView: View {
    let state: AppState
    let data: WindowDataModel
    let updater: UpdaterModel?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                content
                    .frame(maxWidth: Metrics.homeContentMaxWidth, alignment: .leading)
                    .padding(.horizontal, Metrics.spacingLarge)
                    .padding(.vertical, Metrics.homeContentPadding)
                    .frame(maxWidth: .infinity)
            }
            HomeSystemStrip(syncStatus: state.syncStatus, updater: updater)
        }
        .background(Palette.bg)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Metrics.homeSectionSpacing) {
            HomeVerdictHeader(
                status: status,
                findingCount: data.findingGroups.count,
                totalItemCount: totalItemCount,
                monitoredSurfaceCount: MonitoredSurface.allCases.count
            )
            surfacesSection
        }
    }

    private var surfacesSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            SectionLabel(title: "Surfaces")
            HomeSurfaceList(summaries: state.summaries, severityBySurface: severityBySurface)
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

    /// The worst open severity per surface, used to flag the surface rows.
    private var severityBySurface: [MonitoredSurface: Severity] {
        data.findingGroups.reduce(into: [:]) { result, group in
            let severity = group.representative.severity
            let surface = group.representative.surface
            result[surface] = Swift.max(result[surface] ?? severity, severity)
        }
    }
}
