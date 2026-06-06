import SwiftUI

// MARK: - DetailRow

/// One labelled fact in a detail pane: a fixed-width label and a selectable value. Used across
/// the finding and inventory detail views so their layout stays consistent in one place.
struct DetailRow<Value: View>: View {
    let label: String
    @ViewBuilder let value: Value

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.spacingMedium) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Palette.inkSubtle)
                .frame(width: Metrics.detailLabelWidth, alignment: .leading)
            value
                .font(.callout)
                .foregroundStyle(Palette.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension DetailRow where Value == Text {
    init(_ label: String, _ value: String) {
        self.init(label: label) { Text(value) }
    }
}
