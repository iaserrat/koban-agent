import SwiftUI

/// One line in the activity feed: change kind, item, detail, occurrence count, and relative
/// time. Pure content shared by the panel (grouped, so `count` may exceed one) and the window's
/// raw log (each event passed individually, `count` of one).
struct ActivityRow: View {
    let event: ChangeEvent
    var count = 1
    let context: DisplayContext

    var body: some View {
        HStack(spacing: Metrics.spacingSmall) {
            Image(systemName: event.kind.systemImageName)
                .foregroundStyle(Palette.inkSubtle)
                .frame(width: Metrics.iconWidth)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Metrics.spacingTight) {
                    Text(event.itemName)
                        .font(.callout)
                        .foregroundStyle(Palette.ink)
                    CountBadge(count: count)
                }
                Text(event.detail)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Palette.inkSubtle)
                    .lineLimit(context.rationaleLineLimit)
            }
            Spacer()
            Text(event.timestamp, format: .relative(presentation: .named))
                .font(.caption2)
                .foregroundStyle(Palette.inkSubtle)
        }
    }
}
