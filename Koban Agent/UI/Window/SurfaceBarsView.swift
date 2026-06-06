import SwiftUI

/// The window's right rail: one horizontal bar per watched surface, scaled to the largest, so the
/// inventory volume reads at a glance. A surface with open findings draws amber; the rest draw the
/// Fleet Violet accent. Tapping a bar filters the stream to that surface (and tapping the active
/// one clears it), which is the navigation the sidebar's surface rows used to provide.
struct SurfaceBarsView: View {
    let counts: [MonitoredSurface: Int]
    let flaggedSurfaces: Set<MonitoredSurface>
    let selected: MonitoredSurface?
    let onSelect: (MonitoredSurface) -> Void

    private var surfaces: [MonitoredSurface] {
        MonitoredSurface.allCases.filter { (counts[$0] ?? 0) > 0 }
    }

    private var maxCount: Int {
        counts.values.max() ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacingMedium) {
                    ForEach(surfaces) { bar($0) }
                }
                .padding(Metrics.spacingLarge)
            }
            legend
        }
        .frame(width: Metrics.surfaceAsideWidth)
        .background(Palette.bgDeep)
        .overlay(alignment: .leading) {
            Rectangle().fill(Palette.border).frame(width: Metrics.hairline)
        }
    }

    private var header: some View {
        HStack {
            SectionLabel(title: "By surface")
            Spacer()
        }
        .padding(.horizontal, Metrics.spacingLarge)
        .frame(height: Metrics.streamHeaderHeight)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.border).frame(height: Metrics.hairline)
        }
    }

    private func bar(_ surface: MonitoredSurface) -> some View {
        let count = counts[surface] ?? 0
        let fraction = maxCount > 0 ? Double(count) / Double(maxCount) : 0
        let flagged = flaggedSurfaces.contains(surface)
        return Button {
            onSelect(surface)
        } label: {
            VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
                HStack(spacing: Metrics.spacingSmall) {
                    MonogramChip(surface: surface, isHighlighted: selected == surface)
                    Text(surface.displayName)
                        .font(.callout)
                        .foregroundStyle(Palette.inkMuted)
                    Spacer()
                    Text(count, format: .number)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Palette.inkSubtle)
                }
                track(fraction: fraction, flagged: flagged, active: selected == surface)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func track(fraction: Double, flagged: Bool, active: Bool) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Metrics.surfaceBarCornerRadius, style: .continuous)
                    .fill(Palette.surface)
                RoundedRectangle(cornerRadius: Metrics.surfaceBarCornerRadius, style: .continuous)
                    .fill(flagged ? Palette.alert : Palette.accent)
                    .frame(width: max(0, geometry.size.width * fraction))
            }
        }
        .frame(height: Metrics.surfaceBarHeight)
        .overlay {
            if active {
                RoundedRectangle(cornerRadius: Metrics.surfaceBarCornerRadius, style: .continuous)
                    .strokeBorder(Palette.borderStrong, lineWidth: Metrics.hairline)
            }
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            legendRow(color: Palette.accent, label: "watched, clean")
            legendRow(color: Palette.alert, label: "has findings")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metrics.spacingLarge)
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.border).frame(height: Metrics.hairline)
        }
    }

    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: Metrics.spacingSmall) {
            RoundedRectangle(cornerRadius: Metrics.surfaceBarCornerRadius, style: .continuous)
                .fill(color)
                .frame(width: Metrics.statusDotSize, height: Metrics.statusDotSize)
            Text(label)
                .font(.caption)
                .foregroundStyle(Palette.inkSubtle)
        }
    }
}
