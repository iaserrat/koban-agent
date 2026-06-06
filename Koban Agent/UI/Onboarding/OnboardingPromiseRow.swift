import SwiftUI

/// One line of Koban's first-run trust promise: an accent glyph and the concrete claim beside it.
/// The promises are what makes Koban's constrained design a feature, so they read plainly, never as
/// marketing.
struct OnboardingPromiseRow: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.spacingMedium) {
            Image(systemName: symbol)
                .font(.callout)
                .foregroundStyle(Palette.accent)
                .frame(width: Metrics.iconWidth)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
