import SwiftUI

/// A small rounded-square chip carrying an ecosystem's two-letter monogram, the consistent stand-in
/// for the mismatched per-service icons we used to draw. Monochrome by default (a tonal fill with a
/// mono mark); it picks up the Fleet Violet accent when its row is highlighted, so the chip doubles
/// as the row's selection cue.
struct MonogramChip: View {
    let surface: MonitoredSurface
    var isHighlighted = false

    var body: some View {
        IconChip(isHighlighted: isHighlighted) {
            Text(surface.monogram)
                .font(.system(size: Metrics.monogramFontSize, weight: .semibold, design: .monospaced))
                .foregroundStyle(isHighlighted ? Palette.accent : Palette.inkMuted)
        }
    }
}
