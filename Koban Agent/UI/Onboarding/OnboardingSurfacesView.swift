import SwiftUI

/// Step two: the surfaces Koban watches, and the three promises that make its constrained design a
/// trust feature rather than a limitation. This is the screen that earns confidence before the
/// first scan reads the user's machine.
struct OnboardingSurfacesView: View {
    let step: OnboardingModel.Step
    let onContinue: () -> Void
    let onBack: () -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Metrics.spacingSmall),
        count: Metrics.onboardingSurfaceColumns
    )

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.onboardingSectionSpacing) {
            VStack(alignment: .leading, spacing: Metrics.onboardingHeadlineSpacing) {
                Text("What Koban watches")
                    .font(.title)
                    .fontWeight(.semibold)
                    .tracking(Metrics.headingTracking)
                Text("Koban reads each tool's own files: package receipts, lockfiles, and agent config.")
                    .font(.callout)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            surfacesPanel
            VStack(alignment: .leading, spacing: Metrics.onboardingItemSpacing) {
                OnboardingPromiseRow(
                    symbol: Symbols.promisePrivacy,
                    text: "Reads only public, on-disk files. Never your keystrokes, prompts, or secrets."
                )
                OnboardingPromiseRow(
                    symbol: Symbols.promiseNoEntitlement,
                    text: "No Full Disk Access, no kernel extension, no system permission prompts."
                )
                OnboardingPromiseRow(
                    symbol: Symbols.promiseReportsOnly,
                    text: "Reports and inventories. Koban never blocks, quarantines, or edits anything."
                )
            }
            Spacer()
            OnboardingControls(
                step: step,
                primaryTitle: "Index this Mac",
                onPrimary: onContinue,
                onBack: onBack,
                onQuit: nil
            )
        }
    }

    private var surfacesPanel: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Metrics.spacingTight) {
            ForEach(MonitoredSurface.allCases) { surface in
                HStack(spacing: Metrics.spacingSmall) {
                    MonogramChip(surface: surface)
                    Text(surface.displayName)
                        .font(.callout)
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 0)
                }
                .frame(height: Metrics.onboardingSurfaceRowHeight)
            }
        }
        .padding(Metrics.spacingSmall)
        .background(
            RoundedRectangle(cornerRadius: Metrics.panelCornerRadius, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.panelCornerRadius, style: .continuous)
                .strokeBorder(Palette.borderStrong, lineWidth: Metrics.hairline)
        )
    }
}
