import SwiftUI

/// The dot colour for one surface's health: violet when live and healthy, subtle when idle, amber
/// when stale, crimson when degraded. The same severity-free palette the status header reads from,
/// kept in one place so the home dashboard's surface cards stay in step with it.
extension SurfaceHealthState {
    var tint: Color {
        switch self {
        case .idle: Palette.inkSubtle
        case .healthy: Palette.accent
        case .stale: Palette.alert
        case .degraded: Palette.critical
        }
    }
}
