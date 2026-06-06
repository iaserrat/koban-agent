import SwiftUI

/// Step three: the first load. Koban primes every surface here, and this screen shows it happening,
/// then lands on what it found. The progress is the engine's real work, reported through
/// `OnboardingModel`; the item counts come from the same read model the panel uses. When it
/// finishes, "Open Koban" hands the user to their freshly indexed machine.
struct OnboardingIndexingView: View {
    let onboarding: OnboardingModel
    let state: AppState
    let onComplete: () -> Void

    /// A single animated cursor (0...1) that fills the bar and reveals the surface rows in order. It
    /// eases toward the engine's real progress, so a machine already primed by the time the user
    /// arrives still plays a brief, honest reveal of finished work, while a slower one tracks the
    /// baseline as it lands.
    @State private var revealed = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.onboardingSectionSpacing) {
            header
            progressBar
            surfaceList
            Spacer()
            footer
        }
        .animation(.easeOut(duration: Metrics.onboardingRevealSeconds), value: showComplete)
        .onAppear { reveal(to: onboarding.progress) }
        .onChange(of: onboarding.progress) { _, progress in reveal(to: progress) }
    }

    private func reveal(to progress: Double) {
        withAnimation(.easeOut(duration: Metrics.onboardingRevealSeconds)) { revealed = progress }
    }

    /// Complete only once the reveal has caught up to a finished baseline, so the bar and checklist
    /// always finish filling before the screen flips to its summary.
    private var showComplete: Bool {
        onboarding.isIndexingComplete && revealed >= 1
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Metrics.onboardingHeadlineSpacing) {
            Text(showComplete ? "Your Mac is indexed" : "Indexing your Mac")
                .font(.title)
                .fontWeight(.semibold)
                .tracking(Metrics.headingTracking)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var subtitle: String {
        guard showComplete else {
            return """
            Taking the first inventory of each surface. This first scan is a silent baseline, so the \
            software you already have won't show up as a change.
            """
        }
        return "Koban found \(itemPhrase) across \(surfacePhrase). It is now watching for changes."
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Palette.surfaceRaised)
                Capsule(style: .continuous)
                    .fill(Palette.accent)
                    .frame(width: geometry.size.width * revealed)
            }
        }
        .frame(height: Metrics.onboardingProgressBarHeight)
    }

    private var surfaceList: some View {
        VStack(spacing: 0) {
            ForEach(surfaces.indices, id: \.self) { index in
                let surface = surfaces[index]
                OnboardingSurfaceProgressRow(
                    surface: surface,
                    state: revealState(at: index),
                    itemCount: state.summaries[surface]?.itemCount
                )
            }
        }
    }

    /// Maps the reveal cursor onto one surface row: rows fill in order as the cursor crosses each
    /// one's slice of the bar, so the checklist tracks the bar exactly.
    private func revealState(at index: Int) -> OnboardingModel.IndexingState {
        let total = Double(surfaces.count)
        guard total > 0 else { return .pending }
        let start = Double(index) / total
        let end = Double(index + 1) / total
        if revealed >= end { return .indexed }
        if revealed >= start { return .indexing }
        return .pending
    }

    @ViewBuilder private var footer: some View {
        if showComplete {
            PrimaryButton(title: "Open Koban", action: onComplete)
                .transition(.opacity.combined(with: .offset(y: Metrics.onboardingRowRise)))
        } else {
            Text("This first scan runs once. You can keep working while it finishes.")
                .font(.caption)
                .foregroundStyle(Palette.inkSubtle)
                .frame(maxWidth: .infinity)
        }
    }

    /// Falls back to every surface before the engine reports its set, so the list never flashes
    /// empty on the way into this step.
    private var surfaces: [MonitoredSurface] {
        onboarding.surfaces.isEmpty ? MonitoredSurface.allCases : onboarding.surfaces
    }

    private var itemPhrase: String {
        let count = state.summaries.values.reduce(0) { $0 + $1.itemCount }
        return "\(count.formatted()) item\(count == 1 ? "" : "s")"
    }

    private var surfacePhrase: String {
        let count = surfaces.count
        return "\(count) surface\(count == 1 ? "" : "s")"
    }
}
