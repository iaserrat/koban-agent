import Foundation

/// Where a shared component is being rendered. A single row/section view is defined once and
/// rendered in both the menu-bar panel and the extended window; this value is what dictates the
/// behavioural invariant for that context - density and truncation here, tappability at the call
/// site - so the panel/window difference lives in one place, not in duplicated views (CLAUDE.md).
enum DisplayContext {
    /// The compact, glanceable menu-bar popover.
    case panel
    /// The roomy extended window.
    case window

    /// How many lines of a row's detail to show. The panel stays terse; the window shows the
    /// full text.
    var rationaleLineLimit: Int? {
        switch self {
        case .panel: Metrics.rationaleLineLimit
        case .window: nil
        }
    }

    /// Whether a finding row shows its rationale subtitle. In the panel the title and item name
    /// already say what and where, so the redundant why is left to the window, keeping the glance
    /// to one line per finding.
    var showsFindingRationale: Bool {
        switch self {
        case .panel: false
        case .window: true
        }
    }
}
