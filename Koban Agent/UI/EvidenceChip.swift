import SwiftUI

/// A bordered chip that presents one piece of on-disk evidence as data: a leading glyph, a
/// monospaced value (a path, a command, a matched rule field), and an optional trailing tag. It is
/// the detail thread's equivalent of Cursor's file rows, so paths and rule hits read as inspectable
/// records rather than prose. Paths truncate in the middle so both ends stay visible.
struct EvidenceChip: View {
    let symbol: String
    let value: String
    var trailing: String?

    var body: some View {
        HStack(spacing: Metrics.spacingSmall) {
            Image(systemName: symbol)
                .foregroundStyle(Palette.inkSubtle)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
            if let trailing {
                Spacer(minLength: Metrics.spacingSmall)
                Text(trailing)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)
            }
        }
        .padding(.horizontal, Metrics.chipPaddingH)
        .padding(.vertical, Metrics.chipPaddingV)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Metrics.chipCornerRadius, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.chipCornerRadius, style: .continuous)
                .strokeBorder(Palette.border, lineWidth: Metrics.hairline)
        )
    }
}
