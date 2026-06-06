import SwiftUI

/// Step one: the brand mark, the value proposition in one line, and what Koban does in two
/// sentences. The job is to say what this is and earn the next click, not to teach the product.
struct OnboardingWelcomeView: View {
    let step: OnboardingModel.Step
    let onContinue: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: Metrics.onboardingSectionSpacing) {
                BrandMark(size: Metrics.onboardingHeroMarkSize)
                    .foregroundStyle(Palette.accent)
                VStack(spacing: Metrics.onboardingHeadlineSpacing) {
                    Text("Endpoint visibility for your dev machine")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .tracking(Metrics.headingTracking)
                    Text(
                        """
                        Koban inventories the packages, developer tools, and AI agents on your Mac, \
                        then watches them for the changes that signal compromise. It detects and \
                        reports, runs locally, and never blocks.
                        """
                    )
                    .font(.callout)
                    .foregroundStyle(Palette.inkMuted)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            OnboardingControls(
                step: step,
                primaryTitle: "Get started",
                onPrimary: onContinue,
                onQuit: onQuit
            )
        }
    }
}
