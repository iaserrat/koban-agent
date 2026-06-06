import SwiftUI

/// The at-a-glance sync state in the dashboard's system strip: a dot and a short label resolved from
/// `SyncStatus.phase`. A stuck upload reads crimson, an in-progress drain breathes violet, a drained
/// outbox is a calm "Synced", and an unconfigured sensor simply says it is off.
struct HomeSyncGlance: View {
    let status: SyncStatus

    var body: some View {
        HStack(spacing: Metrics.spacingTight) {
            indicator
            Text(label)
                .font(.caption2)
                .foregroundStyle(Palette.inkMuted)
        }
    }

    @ViewBuilder private var indicator: some View {
        if status.phase == .syncing {
            LiveIndicator(color: Palette.accent)
        } else {
            StatusDot(color: dotColor)
        }
    }

    private var dotColor: Color {
        switch status.phase {
        case .off: Palette.inkSubtle
        case .neverSynced: Palette.inkMuted
        case .syncing, .upToDate: Palette.accent
        case .failing: Palette.critical
        }
    }

    private var label: String {
        switch status.phase {
        case .off: "Sync off"
        case .neverSynced: "Sync ready"
        case .syncing: "Syncing \(status.pendingCount)"
        case .failing: status.failedCount == 1 ? "1 sync error" : "\(status.failedCount) sync errors"
        case .upToDate: syncedLabel
        }
    }

    private var syncedLabel: String {
        guard let lastSyncedAt = status.lastSyncedAt else { return "Synced" }
        return "Synced \(lastSyncedAt.formatted(.relative(presentation: .named)))"
    }
}
