import SwiftUI

/// The "See N more" control shown when a glance list is truncated. A real button that hands off
/// to the extended window (or to the matching window section), so the panel never shows a count
/// that does nothing. Renders nothing when the list is fully shown.
struct OverflowButton: View {
    let shown: Int
    let total: Int
    let action: () -> Void

    var body: some View {
        if total > shown {
            Button(action: action) {
                Text("See \(total - shown) more")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, Metrics.rowInsetH)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}
