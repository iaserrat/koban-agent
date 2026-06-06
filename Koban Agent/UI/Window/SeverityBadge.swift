import SwiftUI

/// A small pill naming a severity with its dot and tint, shown in the detail panel's header so a
/// flagged selection states its weight up front. Defined once and reused by both detail bodies.
struct SeverityBadge: View {
    let severity: Severity

    var body: some View {
        HStack(spacing: Metrics.spacingTight) {
            SeverityDot(severity: severity)
            Text(severity.label)
                .font(.caption)
                .foregroundStyle(severity.tint)
        }
        .padding(.horizontal, Metrics.chipPaddingH)
        .padding(.vertical, Metrics.badgePaddingV)
        .background(Capsule().fill(Palette.surface))
        .overlay(Capsule().strokeBorder(Palette.border, lineWidth: Metrics.hairline))
    }
}
