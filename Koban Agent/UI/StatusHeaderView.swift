import SwiftUI

/// The popover header: the Koban mark and wordmark on the left, the monitoring status on the
/// right. The status dot's colour carries the agent's state at a glance, with the word beside it
/// as the single, canonical label.
struct StatusHeaderView: View {
    let state: AppState

    var body: some View {
        HStack(spacing: Metrics.spacingSmall) {
            BrandMark(size: Metrics.headerMarkSize)
                .foregroundStyle(Palette.accent)
            Text("Koban")
                .font(.headline)
                .foregroundStyle(Palette.ink)
            Spacer()
            HStack(spacing: Metrics.spacingTight) {
                StatusDot(color: statusColor)
                Text(statusText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(statusInk)
            }
        }
    }

    private var statusText: String {
        if state.readModelError != nil {
            SurfaceHealthLabels.readModelUnavailable
        } else if overallHealth == .degraded {
            SurfaceHealthLabels.degraded
        } else {
            state.isMonitoring ? "Monitoring" : "Idle"
        }
    }

    private var isHealthy: Bool {
        state.readModelError == nil && overallHealth != .degraded
    }

    private var isLive: Bool {
        isHealthy && state.isMonitoring
    }

    private var statusColor: Color {
        if isHealthy {
            isLive ? Palette.accent : Palette.inkSubtle
        } else {
            Palette.critical
        }
    }

    private var statusInk: Color {
        isHealthy ? Palette.inkMuted : Palette.critical
    }

    private var overallHealth: SurfaceHealthState {
        state.summaries.values.map(\.healthState).max() ?? .idle
    }
}
