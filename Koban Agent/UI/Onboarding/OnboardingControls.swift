import SwiftUI

/// The shared bottom controls for the read-at-your-pace steps (welcome, surfaces): the primary
/// forward action, with the step dots centred beneath it and optional Back and Quit text buttons on
/// the flanks. One definition so both steps carry the same footer, differing only by which side
/// controls they pass. The indexing step has its own foot, since it commits only once.
struct OnboardingControls: View {
    let step: OnboardingModel.Step
    let primaryTitle: String
    let onPrimary: () -> Void
    var onBack: (() -> Void)?
    var onQuit: (() -> Void)?

    var body: some View {
        VStack(spacing: Metrics.onboardingItemSpacing) {
            PrimaryButton(title: primaryTitle, action: onPrimary)
            ZStack {
                OnboardingStepDots(current: step)
                HStack {
                    if let onBack { textButton("Back", systemImage: Symbols.chevronBack, action: onBack) }
                    Spacer()
                    if let onQuit { textButton("Quit", action: onQuit) }
                }
            }
        }
    }

    private func textButton(
        _ title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Metrics.spacingTight) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(Palette.inkSubtle)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
