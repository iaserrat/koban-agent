import SwiftUI

/// Maps a `Severity` to its visual treatment, so colour and icon choices live in one place
/// rather than scattered across views.
extension Severity {
    var tint: Color {
        switch self {
        case .info: Palette.inkMuted
        case .notable: Palette.alert
        case .suspicious, .critical: Palette.critical
        }
    }

    var systemImageName: String {
        switch self {
        case .info: "info.circle"
        case .notable: "exclamationmark.triangle"
        case .suspicious: "exclamationmark.octagon.fill"
        case .critical: "exclamationmark.octagon.fill"
        }
    }

    var label: String {
        switch self {
        case .info: "Info"
        case .notable: "Notable"
        case .suspicious: "Suspicious"
        case .critical: "Critical"
        }
    }
}
