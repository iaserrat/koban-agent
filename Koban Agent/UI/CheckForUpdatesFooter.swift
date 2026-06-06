import SwiftUI

/// The manual "Check for Updates" control, sat in the panel footer beside Quit. Sparkle also checks
/// in the background on its own schedule; this is the explicit, on-demand path. Disabled while a
/// check is already running, mirroring `UpdaterModel.canCheckForUpdates`.
struct CheckForUpdatesFooter: View {
    let updater: UpdaterModel

    var body: some View {
        RowButton {
            updater.checkForUpdates()
        } label: {
            HStack(spacing: Metrics.spacingSmall) {
                Image(systemName: Symbols.checkForUpdates)
                    .frame(width: Metrics.iconWidth)
                Text("Check for Updates")
            }
        }
        .disabled(!updater.canCheckForUpdates)
    }
}
