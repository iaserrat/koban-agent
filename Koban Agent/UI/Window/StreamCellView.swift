import SwiftUI

/// Draws one cell of a stream row for a given column kind. Keeping the per-kind switch here lets
/// `StreamRowView` stay a thin layout that just places cells at their column widths, and makes the
/// table's columns pure data (`MonitorScope.columns`). One row model, every scope (CLAUDE.md).
struct StreamCellView: View {
    let kind: StreamColumnKind
    let row: StreamRow

    var body: some View {
        cell
            .padding(.trailing, Metrics.spacingMedium)
    }

    @ViewBuilder private var cell: some View {
        switch kind {
        case .time: time
        case .event: event
        case .surface: surface
        case .context: context
        case .detail: detailText
        case .version: version
        case .origin: origin
        case .severity: severityLabel
        case .flag: flag
        }
    }

    private var time: some View {
        Text(row.timestamp.map { $0.formatted(.dateTime.hour().minute().second()) } ?? "")
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(Palette.inkSubtle)
    }

    @ViewBuilder private var event: some View {
        switch row.badge {
        case let .change(kind):
            Label {
                Text(kind.displayName).foregroundStyle(Palette.ink)
            } icon: {
                Image(systemName: kind.systemImageName)
                    .foregroundStyle(row.severity?.tint ?? Palette.inkSubtle)
            }
            .font(.callout)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
        case let .rule(title):
            Text(title)
                .font(.callout)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .truncationMode(.tail)
        case .blank:
            EmptyView()
        }
    }

    private var surface: some View {
        HStack(spacing: Metrics.spacingSmall) {
            MonogramChip(surface: row.surface)
            Text(row.surface.displayName)
                .font(.callout)
                .foregroundStyle(Palette.inkMuted)
                .lineLimit(1)
        }
    }

    private var context: some View {
        HStack(spacing: Metrics.spacingSmall) {
            Text(row.name)
                .font(.callout)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            if let path = row.path {
                Text(path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Palette.inkSubtle)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var detailText: some View {
        Text(row.detail ?? "")
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(Palette.inkSubtle)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var version: some View {
        Text(row.version ?? "")
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(Palette.inkMuted)
            .lineLimit(1)
    }

    private var origin: some View {
        Text(row.origin ?? "")
            .font(.callout)
            .foregroundStyle(Palette.inkSubtle)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    @ViewBuilder private var severityLabel: some View {
        if let severity = row.severity {
            Text(severity.label)
                .font(.callout)
                .foregroundStyle(severity.tint)
        }
    }

    @ViewBuilder private var flag: some View {
        if let severity = row.severity {
            SeverityDot(severity: severity)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
