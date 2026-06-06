import SwiftUI

/// One indicator-of-compromise finding: severity icon, what and where, why it was flagged, and
/// (when it recurred) how many times. Pure content; the panel wraps it in a `RowButton` and the
/// window renders it inside a selectable `List`. The `context` sets density and truncation.
struct FindingRow: View {
    let finding: Finding
    var count = 1
    let context: DisplayContext

    var body: some View {
        HStack(alignment: .top, spacing: Metrics.spacingSmall) {
            Image(systemName: finding.severity.systemImageName)
                .foregroundStyle(finding.severity.tint)
                .frame(width: Metrics.iconWidth)
            VStack(alignment: .leading, spacing: Metrics.rowLineSpacing) {
                HStack(spacing: Metrics.spacingTight) {
                    Text(finding.title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Text(finding.itemName)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(Palette.inkMuted)
                        .lineLimit(1)
                    CountBadge(count: count)
                    if case .window = context {
                        Spacer(minLength: Metrics.spacingSmall)
                        Text(finding.timestamp, format: .relative(presentation: .named))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Palette.inkSubtle)
                    }
                }
                if context.showsFindingRationale {
                    Text(finding.rationale)
                        .font(.caption)
                        .foregroundStyle(Palette.inkMuted)
                        .lineLimit(context.rationaleLineLimit)
                }
            }
        }
    }
}
