import SwiftUI

/// One inventory item in the window's list: name, version, and a terse origin. The full
/// provenance lives in the detail pane.
struct InventoryItemRow: View {
    let item: InventoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.rowLineSpacing) {
            HStack(spacing: Metrics.spacingSmall) {
                Text(item.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                if let version = item.version {
                    Text(version)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Palette.inkMuted)
                }
            }
            Text(item.provenance.origin)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Palette.inkSubtle)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, Metrics.spacingTight)
    }
}
