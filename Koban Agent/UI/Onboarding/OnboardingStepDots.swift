import SwiftUI

/// The step-position indicator at the foot of the first-run flow: one dot per step, the current
/// one stretched into a short accent capsule. Read-only; it shows where the user is, it is not a
/// control.
struct OnboardingStepDots: View {
    let current: OnboardingModel.Step

    var body: some View {
        HStack(spacing: Metrics.spacingSmall) {
            ForEach(OnboardingModel.Step.allCases, id: \.self) { step in
                Capsule(style: .continuous)
                    .fill(step == current ? Palette.accent : Palette.surfaceRaised)
                    .frame(width: dotWidth(for: step), height: Metrics.onboardingStepDotSize)
            }
        }
        .animation(.easeOut(duration: Metrics.onboardingTransitionSeconds), value: current)
    }

    private func dotWidth(for step: OnboardingModel.Step) -> CGFloat {
        step == current ? Metrics.onboardingStepDotActiveWidth : Metrics.onboardingStepDotSize
    }
}
