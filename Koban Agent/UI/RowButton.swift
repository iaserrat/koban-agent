import SwiftUI

/// Wraps row content in a tappable control with a native hover/press highlight, so the glance
/// panel's rows feel like live menu items rather than static text. The window uses `List`
/// selection for the same affordance, so this is the panel's counterpart, not a duplicate.
struct RowButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: Label

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Metrics.rowInsetH)
                .padding(.vertical, Metrics.rowInsetV)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(highlight)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: Metrics.hoverFadeSeconds), value: isHovering)
    }

    private var highlight: some View {
        RoundedRectangle(cornerRadius: Metrics.rowCornerRadius, style: .continuous)
            .fill(isHovering ? Palette.accentSoft : .clear)
    }
}
