import SwiftUI

/// The small severity flag drawn in the stream table's trailing column and beside the detail
/// header: a filled dot in the severity's tint with a soft glow of the same colour, so a flagged
/// row reads at a glance without a heavy badge.
struct SeverityDot: View {
    let severity: Severity

    var body: some View {
        Circle()
            .fill(severity.tint)
            .frame(width: Metrics.severityDotSize, height: Metrics.severityDotSize)
            .background(
                Circle()
                    .fill(severity.tint)
                    .blur(radius: Metrics.liveGlowBlur)
                    .opacity(Metrics.liveGlowDimOpacity)
            )
    }
}
