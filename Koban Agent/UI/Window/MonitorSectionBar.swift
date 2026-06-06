import SwiftUI

/// The slim bar between the toolbar and the table: the current scope's heading and, when a surface
/// bar is filtering the stream, a removable chip naming it. This is where the old window's
/// breadcrumb lived, now that the surface filter replaces the sidebar's surface rows.
struct MonitorSectionBar: View {
    let scope: MonitorScope
    let surfaceFilter: MonitoredSurface?
    let onClearSurface: () -> Void

    var body: some View {
        HStack(spacing: Metrics.spacingSmall) {
            Image(systemName: glyph)
                .foregroundStyle(Palette.inkSubtle)
            Text(scope.title)
                .font(.headline)
                .foregroundStyle(Palette.ink)
            if let surfaceFilter {
                chip(surfaceFilter)
            }
            Spacer()
        }
        .padding(.horizontal, Metrics.spacingLarge)
        .padding(.vertical, Metrics.spacingMedium)
        .background(Palette.bg)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.border).frame(height: Metrics.hairline)
        }
    }

    private var glyph: String {
        switch scope {
        case .home: Symbols.overview
        case .activity: Symbols.activity
        case .findings: Symbols.findings
        case .inventory: Symbols.inventory
        }
    }

    private func chip(_ surface: MonitoredSurface) -> some View {
        HStack(spacing: Metrics.spacingSmall) {
            MonogramChip(surface: surface, isHighlighted: true)
            Text(surface.displayName)
                .font(.callout)
                .foregroundStyle(Palette.ink)
            Button(action: onClearSurface) {
                Image(systemName: Symbols.clearFilter)
                    .foregroundStyle(Palette.inkSubtle)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, Metrics.spacingSmall)
        .padding(.trailing, Metrics.spacingSmall)
        .padding(.vertical, Metrics.spacingTight)
        .background(
            Capsule().fill(Palette.accentSoft)
        )
        .overlay(
            Capsule().strokeBorder(Palette.borderStrong, lineWidth: Metrics.hairline)
        )
    }
}
