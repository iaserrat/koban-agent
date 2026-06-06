import SwiftUI

/// One row of the stream table: its cells placed at their column widths, with the row's tonal
/// states. Selection paints a violet wash and a leading accent bar; hover lifts the row one tonal
/// step; a hairline foot separates rows. Depth comes from tone and hairlines, never shadows.
struct StreamRowView: View {
    let columns: [StreamColumn]
    let row: StreamRow
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                StreamCellView(kind: column.kind, row: row)
                    .streamColumnWidth(column.width)
            }
        }
        .padding(.horizontal, Metrics.spacingLarge)
        .frame(height: Metrics.streamRowHeight)
        .background(background)
        .overlay(alignment: .leading) { selectionBar }
        .overlay(alignment: .bottom) { separator }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering = $0 }
    }

    private var background: Color {
        if isSelected { return Palette.accentSoft }
        return hovering ? Palette.surface : .clear
    }

    @ViewBuilder private var selectionBar: some View {
        if isSelected {
            Rectangle()
                .fill(Palette.accent)
                .frame(width: Metrics.streamSelectionBarWidth)
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(Palette.border)
            .frame(height: Metrics.hairline)
    }
}
