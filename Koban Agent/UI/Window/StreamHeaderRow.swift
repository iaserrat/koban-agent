import SwiftUI

/// The stream table's column header: the same column widths the body rows use, so the labels sit
/// directly above their cells. A recessed strip with a hairline foot, matching the brand's flat
/// tonal depth.
struct StreamHeaderRow: View {
    let columns: [StreamColumn]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                SectionLabel(title: column.title)
                    .padding(.trailing, Metrics.spacingMedium)
                    .streamColumnWidth(column.width)
            }
        }
        .padding(.horizontal, Metrics.spacingLarge)
        .frame(height: Metrics.streamHeaderHeight)
        .background(Palette.bgDeep)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Palette.border)
                .frame(height: Metrics.hairline)
        }
    }
}
