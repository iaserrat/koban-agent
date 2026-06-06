import SwiftUI

/// The first-run window's content: a fixed graphite card that hosts the three steps and slides
/// between them. Forward and back are the only navigation; the indexing step finishes the flow.
/// Dark-only like the rest of Koban, set here so the AppKit-hosted window matches even before the
/// app-level appearance applies.
struct OnboardingRootView: View {
    let onboarding: OnboardingModel
    let state: AppState
    let onComplete: () -> Void
    let onQuit: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            step
                .padding(Metrics.onboardingContentPadding)
        }
        .frame(width: Metrics.onboardingWindowWidth, height: Metrics.onboardingWindowHeight)
        .foregroundStyle(Palette.ink)
        .tint(Palette.accent)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var step: some View {
        switch onboarding.step {
        case .welcome:
            OnboardingWelcomeView(step: onboarding.step, onContinue: advance, onQuit: onQuit)
                .transition(stepTransition)
        case .surfaces:
            OnboardingSurfacesView(step: onboarding.step, onContinue: advance, onBack: goBack)
                .transition(stepTransition)
        case .indexing:
            OnboardingIndexingView(onboarding: onboarding, state: state, onComplete: onComplete)
                .transition(stepTransition)
        }
    }

    private func advance() {
        withAnimation(.easeOut(duration: Metrics.onboardingTransitionSeconds)) { onboarding.advance() }
    }

    private func goBack() {
        withAnimation(.easeOut(duration: Metrics.onboardingTransitionSeconds)) { onboarding.goBack() }
    }

    /// A subtle slide-and-fade between steps; a plain crossfade under Reduce Motion.
    private var stepTransition: AnyTransition {
        guard reduceMotion == false else { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(x: Metrics.onboardingStepSlide)),
            removal: .opacity.combined(with: .offset(x: -Metrics.onboardingStepSlide))
        )
    }
}
