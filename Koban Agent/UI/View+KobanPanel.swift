import SwiftUI

extension View {
    /// The brand's grouped-panel chrome: a surface fill inside a hairline border, the flat-elevation
    /// look (depth from tone and borders, never shadows) the popover's panels and the home
    /// dashboard's tiles and cards all share.
    func kobanPanel(cornerRadius: CGFloat = Metrics.panelCornerRadius) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Palette.borderStrong, lineWidth: Metrics.hairline)
        )
    }
}
