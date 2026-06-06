import SwiftUI

/// One surface's line on the indexing step: its monogram and name, with a trailing state that moves
/// from a quiet pending dot, to the breathing accent indicator while it is being read, to its item
/// count and a check once baselined. The trailing state is the row's only moving part, so the list
/// reads as a calm checklist filling in.
struct OnboardingSurfaceProgressRow: View {
    let surface: MonitoredSurface
    let state: OnboardingModel.IndexingState
    let itemCount: Int?

    var body: some View {
        HStack(spacing: Metrics.spacingMedium) {
            MonogramChip(surface: surface, isHighlighted: state == .indexing)
            Text(surface.displayName)
                .foregroundStyle(state == .pending ? Palette.inkMuted : Palette.ink)
            Spacer()
            trailing
        }
        .frame(height: Metrics.onboardingIndexRowHeight)
        .animation(.easeOut(duration: Metrics.onboardingTransitionSeconds), value: state)
    }

    @ViewBuilder private var trailing: some View {
        switch state {
        case .pending:
            Circle()
                .fill(Palette.surfaceRaised)
                .frame(width: Metrics.statusDotSize, height: Metrics.statusDotSize)
                .transition(.opacity)
        case .indexing:
            LiveIndicator(color: Palette.accent)
                .transition(.opacity)
        case .indexed:
            HStack(spacing: Metrics.spacingSmall) {
                if let itemCount {
                    Text(itemCount.formatted())
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(Palette.inkMuted)
                }
                Image(systemName: Symbols.indexed)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Palette.accent)
            }
            .transition(.opacity)
        }
    }
}
