import SwiftUI

/// Maps the home dashboard's `SystemStatus` verdict to its visual treatment, so colour, glyph, and
/// motion live in one place. All-clear takes the Fleet Violet "live" accent rather than a green the
/// brand does not own; findings borrow their own severity's tint and symbol.
extension SystemStatus {
    var tint: Color {
        switch self {
        case .allClear: Palette.accent
        case .starting: Palette.inkSubtle
        case .degraded: Palette.alert
        case .dataUnavailable: Palette.critical
        case let .findings(severity): severity.tint
        }
    }

    /// The shield-family glyph for the verdict signal: a calm check when clear, a plain shield while
    /// starting, a flagged shield when monitoring is degraded, and the finding's own severity symbol
    /// when something is flagged.
    var systemImageName: String {
        switch self {
        case .allClear: Symbols.allClear
        case .starting: Symbols.shield
        case .degraded: Symbols.findings
        case .dataUnavailable: Symbols.warning
        case let .findings(severity): severity.systemImageName
        }
    }

    /// Whether the verdict signal breathes. Only the in-progress states (live and starting) pulse; a
    /// problem holds still so the alarm reads as steady, not animated.
    var isLive: Bool {
        switch self {
        case .allClear, .starting: true
        case .degraded, .dataUnavailable, .findings: false
        }
    }
}
