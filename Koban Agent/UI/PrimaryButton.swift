import SwiftUI

/// The filled Fleet Violet call-to-action. The app's one prominent action button, used by the
/// onboarding steps where a single forward action carries the screen. `RowButton` is its quiet
/// counterpart for list rows; this is for the primary commit. Hover lays a soft white wash over the
/// accent fill, matching the panel's restrained hover language.
struct PrimaryButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(isEnabled ? Palette.ink : Palette.inkSubtle)
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.onboardingButtonHeight)
                .background(background)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: Metrics.hoverFadeSeconds), value: isHovering)
        .disabled(isEnabled == false)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: Metrics.onboardingButtonCornerRadius, style: .continuous)
            .fill(isEnabled ? Palette.accent : Palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.onboardingButtonCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(hoverWashOpacity))
            )
    }

    private var hoverWashOpacity: Double {
        isHovering && isEnabled ? Metrics.onboardingButtonHoverOpacity : 0
    }
}
