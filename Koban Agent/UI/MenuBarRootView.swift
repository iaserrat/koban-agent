import SwiftUI

/// The popover shown from the menu-bar icon: a glance surface. Status, per-surface summaries,
/// the top findings, and recent activity, each handing off to the extended window for depth.
/// A quit control sits at the foot, always one click away (see CLAUDE.md).
///
/// The layout is flat and tonal: a graphite backdrop, a single grouped panel for the inventory,
/// and hairline-separated header and footer, rather than a stack of full-width dividers.
struct MenuBarRootView: View {
    let state: AppState
    let model: MonitorModel

    /// Drives the footer's "Check for Updates" row. Owned by the app delegate alongside the popover.
    let updater: UpdaterModel

    /// Sets the destination on the model, then dismisses the popover and shows the extended window.
    /// Injected by the app delegate, which owns both the popover and the window.
    let presentWindow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RowButton { open(scope: .activity) } label: {
                StatusHeaderView(state: state)
            }
            .padding(Metrics.spacingMedium)
            hairline
            sections
            hairline
            footer
                .padding(Metrics.spacingSmall)
        }
        .frame(width: Metrics.popoverWidth)
        .background(Palette.bg)
        .foregroundStyle(Palette.ink)
        .tint(Palette.accent)
    }

    /// The glance leads with the verdict (findings, or the calm "all clear"), then what is being
    /// watched (the surfaces inventory), then the raw change log. This mirrors the question a
    /// glance answers first - "is anything wrong?" - and the charter's mission order: visibility,
    /// indicators of compromise, inventory/provenance.
    private var sections: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingMedium) {
            FindingsListView(
                findings: state.findings,
                context: .panel,
                onSeeMore: { open(scope: .findings) },
                onSelect: { open(finding: $0) }
            )
            surfacesSection
            ActivityFeedView(
                events: state.recentEvents,
                context: .panel,
                onSeeMore: { open(scope: .activity) }
            )
        }
        .padding(Metrics.spacingMedium)
    }

    private var surfacesSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            SectionLabel(title: "Surfaces")
                .padding(.horizontal, Metrics.rowInsetH)
            surfacesPanel
        }
    }

    private var surfacesPanel: some View {
        VStack(spacing: 0) {
            ForEach(MonitoredSurface.allCases) { surface in
                RowButton { open(surface: surface) } label: {
                    SurfaceSummaryRow(surface: surface, summary: state.summaries[surface])
                }
            }
        }
        .padding(Metrics.panelPadding)
        .background(
            RoundedRectangle(cornerRadius: Metrics.panelCornerRadius, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.panelCornerRadius, style: .continuous)
                .strokeBorder(Palette.borderStrong, lineWidth: Metrics.hairline)
        )
    }

    private var hairline: some View {
        Rectangle()
            .fill(Palette.border)
            .frame(height: Metrics.hairline)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            RowButton { open(scope: .activity) } label: {
                HStack(spacing: Metrics.spacingSmall) {
                    Image(systemName: Symbols.window)
                        .frame(width: Metrics.iconWidth)
                    Text("Open Koban")
                }
            }
            CheckForUpdatesFooter(updater: updater)
            QuitFooter()
        }
    }

    private func open(scope: MonitorScope) {
        model.show(scope: scope)
        presentWindow()
    }

    private func open(surface: MonitoredSurface) {
        model.show(surface: surface)
        presentWindow()
    }

    private func open(finding group: FindingGroup) {
        model.show(finding: group.id)
        presentWindow()
    }
}
