import SwiftUI

/// A small uppercase caption that titles a section of the popover.
struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .tracking(Metrics.labelTracking)
            .foregroundStyle(Palette.inkSubtle)
    }
}
