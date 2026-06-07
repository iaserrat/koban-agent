import SwiftUI

/// Renders a Settings category's leading glyph at a uniform chip size so every sidebar row aligns:
/// an ecosystem's monogram chip, or an SF Symbol in the same tile for the pipeline sections and the
/// ruleset. Both pick up the Fleet Violet accent when their row is selected.
struct SettingsCategoryIconView: View {
    let icon: SettingsCategoryIcon
    let isSelected: Bool

    var body: some View {
        switch icon {
        case let .surface(surface):
            MonogramChip(surface: surface, isHighlighted: isSelected)
        case let .symbol(name):
            IconChip(isHighlighted: isSelected) {
                Image(systemName: name)
                    .font(.system(size: Metrics.monogramFontSize, weight: .semibold))
                    .foregroundStyle(isSelected ? Palette.accent : Palette.inkMuted)
            }
        }
    }
}
