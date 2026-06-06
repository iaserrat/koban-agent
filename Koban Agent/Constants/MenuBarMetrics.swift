import Foundation

/// Layout metrics for the menu-bar status item. The status bar is ~22pt tall; a template glyph
/// reads best a little shorter so it has breathing room and matches neighboring system items.
enum MenuBarMetrics {
    /// Target rendered height, in points, of the status-item icon. Width follows the artwork's
    /// aspect ratio. Independent of the source asset's intrinsic size.
    static let iconHeight: CGFloat = 16
}
