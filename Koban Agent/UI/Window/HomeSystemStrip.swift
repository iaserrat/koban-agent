import SwiftUI

/// The band pinned at the foot of the home dashboard: the agent's own status, kept apart from the
/// observations above it. The version on the left, then the sync glance and the manual update
/// control on the right. The update button is the window-styled sibling of the panel footer's
/// `CheckForUpdatesFooter`: the same action and disabled rule, laid out as an inline chip.
struct HomeSystemStrip: View {
    let syncStatus: SyncStatus
    let updater: UpdaterModel?

    var body: some View {
        HStack(spacing: Metrics.spacingMedium) {
            if let version = AppVersion.current {
                Text("Koban \(version)")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Palette.inkSubtle)
            }
            Spacer()
            HomeSyncGlance(status: syncStatus)
            if let updater {
                updateButton(updater)
            }
        }
        .padding(.horizontal, Metrics.spacingLarge)
        .frame(height: Metrics.homeStripHeight)
        .background(Palette.bgDeep)
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.border).frame(height: Metrics.hairline)
        }
    }

    private func updateButton(_ updater: UpdaterModel) -> some View {
        Button {
            updater.checkForUpdates()
        } label: {
            HStack(spacing: Metrics.spacingTight) {
                Image(systemName: Symbols.checkForUpdates)
                Text("Check for Updates")
            }
            .font(.caption2)
            .foregroundStyle(Palette.inkMuted)
            .padding(.horizontal, Metrics.chipPaddingH)
            .padding(.vertical, Metrics.segmentPaddingV)
            .contentShape(.rect)
            .kobanPanel(cornerRadius: Metrics.segmentGroupCornerRadius)
        }
        .buttonStyle(.plain)
        .disabled(!updater.canCheckForUpdates)
    }
}
