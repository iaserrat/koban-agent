import SwiftUI

/// The small rounded-square tile the UI uses to carry a compact glyph: an ecosystem's two-letter
/// monogram or a settings category's SF Symbol. One container so every chip shares size, corner,
/// fill, and the Fleet Violet wash it takes when its row is highlighted, instead of each call site
/// redrawing the same chrome.
struct IconChip<Content: View>: View {
    var isHighlighted = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(width: Metrics.monogramSize, height: Metrics.monogramSize)
            .background(
                RoundedRectangle(cornerRadius: Metrics.chipCornerRadius, style: .continuous)
                    .fill(isHighlighted ? Palette.accentSoft : Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.chipCornerRadius, style: .continuous)
                    .strokeBorder(
                        isHighlighted ? Palette.accent : Palette.border,
                        lineWidth: Metrics.hairline
                    )
            )
    }
}
