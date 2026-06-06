import SwiftUI

/// One KPI tile on the home dashboard: a small caps label over a large number, with an optional
/// caption beneath. The value can carry a tint (the findings tile colours its count by the worst
/// open severity) so a glance reads the urgency, not just the magnitude.
struct HomeStatTile: View {
    let label: String
    let value: String
    var caption: String?
    var valueTint: Color = Palette.ink

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingTight) {
            SectionLabel(title: label)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(valueTint)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(Palette.inkSubtle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metrics.spacingMedium)
        .kobanPanel()
    }
}
